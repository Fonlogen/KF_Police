--[[
    KF_Police - Servizio (in/out) e roster
    ----------------------------------------------------------------------------
    Servizio interno, senza esx_service: lo stato vive in memoria per la sessione
    e ogni transizione lascia una riga su `kf_police_duty_log`, da cui si ricava
    il monte ore mostrato nella pagina Gestione agenti.
]]

--- identifier -> { source, since, name, job, grade }
local onDuty = {}

function IsOnDuty(identifier)
    return identifier ~= nil and onDuty[identifier] ~= nil
end

function CountOnDuty()
    local count = 0
    for _ in pairs(onDuty) do
        count = count + 1
    end
    return count
end

--- Identifier di tutti gli agenti in servizio, per i blip.
function GetOnDutySources()
    local sources = {}
    for _, entry in pairs(onDuty) do
        sources[#sources + 1] = entry.source
    end
    return sources
end

local function logDuty(info, action)
    Database.Insert(
        'INSERT INTO kf_police_duty_log (identifier, officer_name, action) VALUES (?, ?, ?)',
        { info.identifier, info.name, action })
end

--- @return boolean nuovoStato, string messaggio
function SetDuty(xPlayer, wanted)
    local info = OfficerInfo(xPlayer)
    local current = IsOnDuty(info.identifier)

    if wanted == nil then
        wanted = not current
    end

    if wanted == current then
        return current, current and Locale('duty_on') or Locale('duty_off')
    end

    if wanted then
        local max = Config.Duty.MaxInService or -1
        if max >= 0 and CountOnDuty() >= max then
            return false, Locale('duty_full')
        end

        onDuty[info.identifier] = {
            source = info.source,
            since = os.time(),
            name = info.name,
            job = info.job,
            grade = info.grade,
            gradeLabel = info.gradeLabel,
        }
        logDuty(info, 'in')
    else
        onDuty[info.identifier] = nil
        logDuty(info, 'out')

        if Config.Radio.DisconnectOnDutyEnd then
            TriggerClientEvent('KF_Police:Client:LeaveRadio', info.source)
        end

        if Config.Garage.DespawnOnDuty then
            TriggerClientEvent('KF_Police:Client:DespawnServiceVehicle', info.source)
        end
    end

    TriggerClientEvent('KF_Police:Client:DutyChanged', info.source, wanted)
    Invalidate('roster')
    PushCounters()
    Logger.Audit(xPlayer, wanted and 'duty.in' or 'duty.out', info.identifier)

    return wanted, wanted and Locale('duty_on') or Locale('duty_off')
end

RegisterMdtEndpoint('duty:toggle', 'duty.toggle', function(officer, payload)
    local wanted = payload.onDuty
    if wanted ~= nil then
        wanted = ToBool(wanted)
    end

    local state, message = SetDuty(officer, wanted)

    return MdtOk({ onDuty = state, message = message })
end)

RegisterMdtEndpoint('duty:state', 'mdt.view', function(officer)
    local info = OfficerInfo(officer)

    return MdtOk({
        onDuty = IsOnDuty(info.identifier),
        total = CountOnDuty(),
    })
end)

-- ============================================================================
--  Roster / Gestione agenti (bug U9: la pagina era uno stub)
-- ============================================================================

RegisterMdtEndpoint('duty:roster', 'mdt.view', function(officer, payload)
    local info = OfficerInfo(officer)
    local jobFilter = SanitizeText(payload.job, 32)
    if jobFilter == '' or not Config.AllowedJobs[jobFilter] then
        jobFilter = info.job
    end

    local rows = Database.Query([[
        SELECT u.identifier, u.firstname, u.lastname, u.ssn, u.job, u.job_grade,
               p.mugshot
        FROM users u
        LEFT JOIN kf_police_profiles p ON p.identifier = u.identifier
        WHERE u.job = ?
        ORDER BY u.job_grade DESC, u.lastname ASC
    ]], { jobFilter }) or {}

    -- Ore di servizio degli ultimi 30 giorni, per agente.
    local hours = {}
    local logRows = Database.Query([[
        SELECT identifier, action, at
        FROM kf_police_duty_log
        WHERE at > DATE_SUB(NOW(), INTERVAL 30 DAY) AND identifier IN (
            SELECT identifier FROM users WHERE job = ?
        )
        ORDER BY identifier, at ASC
    ]], { jobFilter }) or {}

    local pendingStart = {}
    for _, row in ipairs(logRows) do
        local at = row.at
        local timestamp = type(at) == 'number' and at or nil

        if not timestamp and type(at) == 'string' then
            local y, m, d, hh, mm, ss = tostring(at):match('(%d+)-(%d+)-(%d+)[T ](%d+):(%d+):(%d+)')
            if y then
                timestamp = os.time({
                    year = tonumber(y), month = tonumber(m), day = tonumber(d),
                    hour = tonumber(hh), min = tonumber(mm), sec = tonumber(ss),
                })
            end
        end

        if timestamp then
            if row.action == 'in' then
                pendingStart[row.identifier] = timestamp
            elseif row.action == 'out' and pendingStart[row.identifier] then
                hours[row.identifier] = (hours[row.identifier] or 0) + (timestamp - pendingStart[row.identifier])
                pendingStart[row.identifier] = nil
            end
        end
    end

    -- Sessione ancora aperta: conta fino ad adesso.
    for identifier, entry in pairs(onDuty) do
        if pendingStart[identifier] then
            hours[identifier] = (hours[identifier] or 0) + (os.time() - pendingStart[identifier])
            pendingStart[identifier] = nil
        elseif entry.since then
            hours[identifier] = (hours[identifier] or 0) + (os.time() - entry.since)
        end
    end

    local list = {}
    for _, row in ipairs(rows) do
        local duty = onDuty[row.identifier]

        list[#list + 1] = {
            identifier = row.identifier,
            firstName = row.firstname or 'Sconosciuto',
            lastName = row.lastname or '',
            ssn = row.ssn,
            mugshot = row.mugshot,
            grade = tonumber(row.job_grade) or 0,
            gradeLabel = GetJobLabel(row.job, row.job_grade),
            onDuty = duty ~= nil,
            online = duty ~= nil or Framework.GetPlayerFromIdentifier(row.identifier) ~= nil,
            secondsThisMonth = math.floor(hours[row.identifier] or 0),
        }
    end

    return MdtOk({
        rows = list,
        total = #list,
        onDuty = CountOnDuty(),
        job = jobFilter,
        canManage = HasPermission(info.job, info.grade, 'society.boss'),
    })
end)

--- Colleghi da mostrare come blip. Solo chi ha lo stesso lavoro e, se
--- configurato, solo chi e' in servizio: un agente non vede i civili.
lib.callback.register('KF_Police:duty:colleagues', function(src)
    local officer = RequirePermission(src, 'mdt.view')
    if not officer then
        return {}
    end

    local jobName = Framework.GetJob(officer)
    local list = {}

    for _, xPlayer in pairs(Framework.GetOnlinePlayers()) do
        local otherJob = Framework.GetJob(xPlayer)

        if otherJob == jobName and xPlayer.source ~= src then
            local isOnDuty = IsOnDuty(xPlayer.identifier)

            if isOnDuty or not Config.ColleagueBlips.OnlyOnDuty then
                local _, _, _, gradeLabel = Framework.GetJob(xPlayer)

                list[#list + 1] = {
                    serverId = xPlayer.source,
                    name = Framework.GetName(xPlayer),
                    gradeLabel = gradeLabel,
                    onDuty = isOnDuty,
                }
            end
        end
    end

    return list
end)

-- ============================================================================
--  Ciclo di vita
-- ============================================================================

AddEventHandler('playerDropped', function()
    local xPlayer = Framework.GetPlayer(source)
    if not xPlayer then
        return
    end

    local identifier = xPlayer.identifier
    if onDuty[identifier] then
        onDuty[identifier] = nil
        Database.Insert(
            'INSERT INTO kf_police_duty_log (identifier, officer_name, action) VALUES (?, ?, ?)',
            { identifier, Framework.GetName(xPlayer), 'out' })
        Invalidate('roster')
        PushCounters()
    end
end)

RegisterNetEvent('esx:setJob', function(_, job)
    local src = source
    local xPlayer = Framework.GetPlayer(src)
    if not xPlayer then
        return
    end

    -- Cambiando lavoro il servizio decade.
    if not IsAllowedJob(job and job.name) and onDuty[xPlayer.identifier] then
        SetDuty(xPlayer, false)
    end
end)

--- All'ingresso in servizio automatico (se configurato).
AddEventHandler('esx:playerLoaded', function(src, xPlayer)
    if not Config.Duty.AutoOnLoad then
        return
    end

    local jobName = Framework.GetJob(xPlayer)
    if IsAllowedJob(jobName) then
        SetDuty(xPlayer, true)
    end
end)

--- Chiudendo la risorsa tutte le sessioni aperte vanno chiuse nel log.
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for identifier, entry in pairs(onDuty) do
        Database.Insert(
            'INSERT INTO kf_police_duty_log (identifier, officer_name, action) VALUES (?, ?, ?)',
            { identifier, entry.name, 'out' })
    end
end)
