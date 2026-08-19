--[[
    KF_Police - Nucleo server e dispatcher dei callback MDT
    ----------------------------------------------------------------------------
    CORREZIONE BUG L4
    ----------------------------------------------------------------------------
    Il vecchio `ServerDataInit` caricava tutti gli utenti e tutti i veicoli in
    RAM e `UpdateMDTData()` li ribroadcastava a `-1` a ogni reato, nota o
    rapporto: con 3000 cittadini insostenibile, e comunque una fuga di dati.
    Qui non esiste piu' nessuna cache globale: ogni schermata chiede solo la
    propria pagina, e le scritture emettono un'invalidazione mirata.

    Tutti i callback della NUI passano da un unico punto (`KF_Police:mdt`), che
    rivalida giocatore, lavoro, permesso di grado e rate limit prima di
    smistare (vedi sv_permissions.lua).
]]

--- endpoint -> { permission, handler }
local endpoints = {}

--- Registra un endpoint MDT.
--- @param name string es. 'citizens:search'
--- @param permission string|nil permesso richiesto
--- @param handler fun(officer: table, payload: table, src: number): any
function RegisterMdtEndpoint(name, permission, handler)
    endpoints[name] = { permission = permission, handler = handler }
end

--- Risposta di errore uniforme.
function MdtError(key, extra)
    local response = { ok = false, error = key, message = Locale(key) }

    if type(extra) == 'table' then
        for k, v in pairs(extra) do
            response[k] = v
        end
    end

    return response
end

--- Risposta positiva uniforme.
function MdtOk(data)
    if type(data) ~= 'table' then
        return { ok = true, data = data }
    end

    data.ok = true
    return data
end

lib.callback.register('KF_Police:mdt', function(src, endpoint, payload)
    if type(endpoint) ~= 'string' then
        return MdtError('invalid_data')
    end

    local definition = endpoints[endpoint]
    if not definition then
        Logger.Warn('Endpoint MDT sconosciuto richiesto da %s: %s', src, endpoint)
        return MdtError('invalid_data')
    end

    if not Database.IsReady() then
        return MdtError('mdt_not_ready')
    end

    local officer, reason = RequirePermission(src, definition.permission)
    if not officer then
        return MdtError(reason or 'no_permission')
    end

    if type(payload) ~= 'table' then
        payload = {}
    end

    local ok, result = pcall(definition.handler, officer, payload, src)
    if not ok then
        Logger.Error('Endpoint %s ha generato un errore: %s', endpoint, tostring(result))
        return MdtError('invalid_data')
    end

    return result or MdtOk({})
end)

-- ============================================================================
--  Invalidazione mirata (sostituisce il broadcast totale)
-- ============================================================================

--- Avvisa i client che una vista e' cambiata: ricaricano solo quella.
--- @param scope 'citizen'|'citizens'|'reports'|'wanted'|'vehicles'|'jail'|'penalcode'|'roster'
--- @param id string|number|nil
function Invalidate(scope, id)
    TriggerClientEvent('KF_Police:Client:Invalidate', -1, {
        scope = scope,
        id = id and tostring(id) or nil,
    })
end

--- Invia solo i contatori di navigazione (badge della sidebar).
function PushCounters()
    TriggerClientEvent('KF_Police:Client:Counters', -1, GetMdtCounters())
end

--- Contatori mostrati nei badge della sidebar.
function GetMdtCounters()
    local wanted = Database.Scalar('SELECT COUNT(*) FROM kf_police_profiles WHERE is_wanted = 1') or 0
    local jailed = Database.Scalar('SELECT COUNT(*) FROM kf_police_jail WHERE released_at IS NULL AND seconds_remaining > 0') or 0
    local openReports = Database.Scalar("SELECT COUNT(*) FROM kf_police_reports WHERE status = 'open'") or 0

    return {
        wanted = tonumber(wanted) or 0,
        jail = tonumber(jailed) or 0,
        reports = tonumber(openReports) or 0,
        duty = CountOnDuty and CountOnDuty() or 0,
    }
end

-- ============================================================================
--  mdt:bootstrap
-- ============================================================================

RegisterMdtEndpoint('bootstrap', 'mdt.view', function(officer)
    local info = OfficerInfo(officer)
    local profile = Database.Single(
        'SELECT mugshot FROM kf_police_profiles WHERE identifier = ?', { info.identifier })

    local pages = {}
    for _, page in ipairs(Config.EnabledPages) do
        pages[#pages + 1] = page
    end

    return MdtOk({
        officer = {
            identifier = info.identifier,
            name = info.name,
            firstName = officer.get and officer.get('firstName') or '',
            lastName = officer.get and officer.get('lastName') or '',
            ssn = info.ssn,
            job = info.job,
            jobLabel = officer.job and officer.job.label or info.job,
            grade = info.grade,
            gradeName = info.gradeName,
            gradeLabel = info.gradeLabel,
            mugshot = profile and profile.mugshot or nil,
            onDuty = IsOnDuty and IsOnDuty(info.identifier) or false,
        },
        permissions = PermissionList(info.job, info.grade),
        pages = pages,
        counters = GetMdtCounters(),
        ui = {
            pageSize = Config.PageSize,
            defaultImage = Config.DefaultImage,
            locale = Config.Locale,
        },
        radio = {
            enabled = Config.Radio.Enabled == true,
        },
    })
end)

-- ============================================================================
--  Avvio
-- ============================================================================

CreateThread(function()
    Database.WaitReady(30000)

    if not Database.IsReady() then
        Logger.Error('Database non pronto: il MDT restera chiuso')
        return
    end

    local items = { Config.OpenItem }
    for _, alias in ipairs(Config.OpenItemAliases or {}) do
        items[#items + 1] = alias
    end

    for _, item in ipairs(items) do
        if item and item ~= '' then
            Framework.RegisterUsableItem(item, function(src)
                if not GetOfficer(src) then
                    return Framework.Notify(src, Locale('not_allowed_job'), 'error')
                end

                TriggerClientEvent('KF_Police:Client:OpenMDT', src)
            end)
        end
    end

    Logger.Info('Pronto (framework=%s, target=%s, inventario=%s)',
        Config.Framework, Config.Target, Config.Inventory)
end)

-- ============================================================================
--  Registrazioni ereditate da esx_policejob
--  Servizi condivisi con altre risorse: vanno mantenuti anche dopo la
--  dismissione di esx_policejob, altrimenti il telefono perde il contatto di
--  allerta e la societa' perde il conto.
-- ============================================================================

CreateThread(function()
    Wait(2000)

    -- Contatto di allerta sul telefono (esx_phone e lb-phone).
    pcall(function()
        TriggerEvent('esx_phone:registerNumber', 'police', 'Polizia', true, true)
    end)

    -- Societa': conto, assunzioni e salari restano su esx_society.
    pcall(function()
        TriggerEvent('esx_society:registerSociety', 'police', 'LSPD',
            Config.Society, Config.Society, Config.Society, { type = 'public' })
    end)
end)

--- Allerta polizia da altre risorse (telefono, negozi, rapine).
--- Sostituisce `esx_policejob:...` mantenendo la stessa semantica.
RegisterNetEvent('KF_Police:Server:Alert', function(data)
    if type(data) ~= 'table' then
        return
    end

    local message = SanitizeText(data.message, 200)
    if message == '' then
        return
    end

    for _, xPlayer in pairs(Framework.GetOnlinePlayers()) do
        local jobName = Framework.GetJob(xPlayer)
        if IsPoliceJob(jobName) then
            TriggerClientEvent('KF_Police:Client:Alert', xPlayer.source, {
                message = message,
                coords = data.coords,
                blip = data.blip ~= false,
            })
        end
    end
end)
