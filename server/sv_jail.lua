--[[
    KF_Police - Carcere
    ----------------------------------------------------------------------------
    Il tempo residuo vive su `kf_police_jail` in secondi, quindi sopravvive a
    disconnessione e restart della risorsa. Il rilascio automatico non dipende
    dall'agente che ha arrestato: lo esegue il server anche se quell'agente e'
    offline.
]]

--- identifier -> { seconds, total, reason, cell, source, ticks }
local jailed = {}

-- ============================================================================
--  Lettura
-- ============================================================================

--- @return table|nil
function GetJailStatus(identifier)
    if not identifier then
        return nil
    end

    local entry = jailed[identifier]
    if entry then
        return {
            jailed = true,
            secondsRemaining = entry.seconds,
            totalSeconds = entry.total,
            reason = entry.reason,
            cell = entry.cell,
            officer = entry.officerName,
            jailedAt = entry.jailedAt,
            label = FormatDuration(entry.seconds),
        }
    end

    local row = Database.Single([[
        SELECT seconds_remaining, total_seconds, reason, cell, officer_name, jailed_at
        FROM kf_police_jail
        WHERE identifier = ? AND released_at IS NULL AND seconds_remaining > 0
    ]], { identifier })

    if not row then
        return { jailed = false, secondsRemaining = 0 }
    end

    return {
        jailed = true,
        secondsRemaining = tonumber(row.seconds_remaining) or 0,
        totalSeconds = tonumber(row.total_seconds) or 0,
        reason = row.reason,
        cell = row.cell,
        officer = row.officer_name,
        jailedAt = row.jailed_at and tostring(row.jailed_at) or nil,
        label = FormatDuration(row.seconds_remaining),
    }
end

--- Cella con posto libero, o nil se sono tutte piene.
local function pickCell()
    local occupancy = {}

    for _, entry in pairs(jailed) do
        if entry.cell then
            occupancy[entry.cell] = (occupancy[entry.cell] or 0) + 1
        end
    end

    for _, cell in ipairs(Config.Jail.Cells or {}) do
        if (occupancy[cell.id] or 0) < (cell.capacity or 1) then
            return cell
        end
    end

    return nil
end

function GetCellById(cellId)
    for _, cell in ipairs(Config.Jail.Cells or {}) do
        if cell.id == cellId then
            return cell
        end
    end

    return nil
end

-- ============================================================================
--  Scrittura
-- ============================================================================

local function persist(identifier, entry)
    Database.Insert([[
        INSERT INTO kf_police_jail
            (identifier, seconds_remaining, total_seconds, reason, officer_id, officer_name, cell)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            seconds_remaining = VALUES(seconds_remaining),
            total_seconds = VALUES(total_seconds),
            reason = VALUES(reason),
            officer_id = VALUES(officer_id),
            officer_name = VALUES(officer_name),
            cell = VALUES(cell),
            jailed_at = IF(kf_police_jail.released_at IS NULL, kf_police_jail.jailed_at, NOW()),
            released_at = NULL
    ]], {
        identifier,
        entry.seconds,
        entry.total,
        entry.reason,
        entry.officerId,
        entry.officerName,
        entry.cell,
    })
end

local function sendToCell(src, cell, entry)
    if not src then
        return
    end

    TriggerClientEvent('KF_Police:Client:Jailed', src, {
        cell = cell and { id = cell.id, label = cell.label, coords = cell.coords } or nil,
        secondsRemaining = entry.seconds,
        reason = entry.reason,
        stripWeapons = Config.Jail.StripWeapons == true,
        bounds = Config.Jail.Bounds,
    })
end

--- Incarcera un cittadino.
--- @param officer table|nil xPlayer dell'agente (nil = sistema)
--- @param identifier string
--- @param seconds number
--- @param reason string|nil
--- @param cellId string|nil
--- @return boolean ok, string messaggio
function JailPlayer(officer, identifier, seconds, reason, cellId)
    if not Config.Jail.Enabled then
        return false, Locale('jail_disabled')
    end

    if not identifier or identifier == '' then
        return false, Locale('invalid_data')
    end

    if jailed[identifier] then
        return false, Locale('jail_already')
    end

    seconds = ClampInt(seconds, 1, Config.Jail.MaxSeconds, 60)

    local cell = cellId and GetCellById(cellId) or pickCell()
    if not cell then
        return false, Locale('jail_no_cell')
    end

    local info = officer and OfficerInfo(officer) or nil

    local entry = {
        seconds = seconds,
        total = seconds,
        reason = SanitizeText(reason, Config.Limits.reason),
        cell = cell.id,
        officerId = info and info.identifier or nil,
        officerName = info and info.name or 'Sistema',
        jailedAt = SqlNow(),
        ticks = 0,
    }

    jailed[identifier] = entry
    persist(identifier, entry)

    local target = Framework.GetPlayerFromIdentifier(identifier)
    if target then
        entry.source = target.source

        if Config.Jail.StripWeapons then
            Inventory.StripWeapons(target.source)
        end

        sendToCell(target.source, cell, entry)
        Framework.Notify(target.source, Locale('jail_received', FormatDuration(seconds)), 'error')
    end

    if officer then
        Logger.Audit(officer, 'jail.send', identifier, {
            seconds = seconds,
            reason = entry.reason,
            cell = cell.id,
        })
    end

    Invalidate('jail')
    Invalidate('citizen', identifier)
    PushCounters()

    return true, Locale('jail_sent', FormatDuration(seconds))
end

--- Rilascia un detenuto. `officer` nil = rilascio automatico a fine pena.
--- @return boolean
function ReleasePlayer(officer, identifier, automatic)
    local entry = jailed[identifier]

    local row = not entry and Database.Single(
        'SELECT identifier FROM kf_police_jail WHERE identifier = ? AND released_at IS NULL',
        { identifier }) or nil

    if not entry and not row then
        return false
    end

    jailed[identifier] = nil

    Database.Update([[
        UPDATE kf_police_jail
        SET seconds_remaining = 0, released_at = NOW()
        WHERE identifier = ?
    ]], { identifier })

    local target = Framework.GetPlayerFromIdentifier(identifier)
    if target then
        TriggerClientEvent('KF_Police:Client:Released', target.source, {
            coords = Config.Jail.Release,
            automatic = automatic == true,
        })
        Framework.Notify(target.source, Locale('jail_release_self'), 'success')
    end

    Logger.Audit(officer or 'system', automatic and 'jail.auto_release' or 'jail.release', identifier)

    Invalidate('jail')
    Invalidate('citizen', identifier)
    PushCounters()

    return true
end

-- ============================================================================
--  Endpoint MDT
-- ============================================================================

RegisterMdtEndpoint('jail:list', 'mdt.jail.view', function()
    local rows = Database.Query([[
        SELECT j.identifier, j.seconds_remaining, j.total_seconds, j.reason, j.cell,
               j.officer_name, j.jailed_at,
               u.firstname, u.lastname, u.ssn, p.mugshot
        FROM kf_police_jail j
        INNER JOIN users u ON u.identifier = j.identifier
        LEFT JOIN kf_police_profiles p ON p.identifier = j.identifier
        WHERE j.released_at IS NULL AND j.seconds_remaining > 0
        ORDER BY j.jailed_at DESC
    ]]) or {}

    local list = {}
    for _, row in ipairs(rows) do
        local live = jailed[row.identifier]
        local remaining = live and live.seconds or tonumber(row.seconds_remaining) or 0

        list[#list + 1] = {
            identifier = row.identifier,
            firstName = row.firstname or 'Sconosciuto',
            lastName = row.lastname or '',
            ssn = row.ssn,
            mugshot = row.mugshot,
            secondsRemaining = remaining,
            totalSeconds = tonumber(row.total_seconds) or 0,
            timeLabel = FormatDuration(remaining),
            reason = row.reason,
            cell = row.cell,
            officer = row.officer_name,
            jailedAt = row.jailed_at and tostring(row.jailed_at) or nil,
            online = live ~= nil and live.source ~= nil,
        }
    end

    return MdtOk({ rows = list, total = #list, cells = Config.Jail.Cells })
end)

RegisterMdtEndpoint('jail:send', 'jail.send', function(officer, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    local months = ClampInt(payload.months, 0, 10000, 0)
    local seconds = ClampInt(payload.seconds, 0, Config.Jail.MaxSeconds, 0)

    if seconds == 0 and months > 0 then
        seconds = months * (Config.Jail.SecondsPerMonth or 30)
    end

    if identifier == '' or seconds <= 0 then
        return MdtError('invalid_data')
    end

    local exists = Database.Scalar('SELECT COUNT(*) FROM users WHERE identifier = ?', { identifier })
    if (tonumber(exists) or 0) == 0 then
        return MdtError('citizen_not_found')
    end

    local ok, message = JailPlayer(officer, identifier, seconds, payload.reason, payload.cell)
    if not ok then
        return MdtError('invalid_data', { message = message })
    end

    return MdtOk({ message = message })
end)

RegisterMdtEndpoint('jail:release', 'jail.release', function(officer, payload)
    local identifier = SanitizeText(payload.identifier, 64)
    if identifier == '' then
        return MdtError('invalid_data')
    end

    if not ReleasePlayer(officer, identifier, false) then
        return MdtError('jail_not_jailed')
    end

    return MdtOk({ message = Locale('jail_released') })
end)

-- ============================================================================
--  Timer
-- ============================================================================

--- Carica i detenuti dal database all'avvio: il tempo residuo e' quello scritto.
Database.OnReady(function()
    local rows = Database.Query([[
        SELECT identifier, seconds_remaining, total_seconds, reason, cell,
               officer_id, officer_name, jailed_at
        FROM kf_police_jail
        WHERE released_at IS NULL AND seconds_remaining > 0
    ]]) or {}

    for _, row in ipairs(rows) do
        jailed[row.identifier] = {
            seconds = tonumber(row.seconds_remaining) or 0,
            total = tonumber(row.total_seconds) or 0,
            reason = row.reason,
            cell = row.cell,
            officerId = row.officer_id,
            officerName = row.officer_name,
            jailedAt = row.jailed_at and tostring(row.jailed_at) or nil,
            ticks = 0,
        }
    end

    if #rows > 0 then
        Logger.Info('Carcere: %d detenuti ripristinati dal database', #rows)
    end
end)

CreateThread(function()
    Database.WaitReady(30000)

    local tick = math.max(1, Config.Jail.Tick or 5)

    while true do
        Wait(tick * 1000)

        if Config.Jail.Enabled then
            for identifier, entry in pairs(jailed) do
                local target = Framework.GetPlayerFromIdentifier(identifier)
                entry.source = target and target.source or nil

                local counts = entry.source ~= nil or Config.Jail.CountOffline

                if counts then
                    entry.seconds = math.max(0, entry.seconds - tick)
                    entry.ticks = (entry.ticks or 0) + 1

                    if entry.source then
                        TriggerClientEvent('KF_Police:Client:JailTick', entry.source, entry.seconds)
                    end

                    if entry.seconds <= 0 then
                        ReleasePlayer(nil, identifier, true)
                    elseif entry.ticks >= (Config.Jail.PersistEvery or 6) then
                        entry.ticks = 0
                        Database.Update(
                            'UPDATE kf_police_jail SET seconds_remaining = ? WHERE identifier = ?',
                            { entry.seconds, identifier })
                    end
                end
            end
        end
    end
end)

--- Rientro in gioco di un detenuto: torna in cella con il tempo corretto.
AddEventHandler('esx:playerLoaded', function(src, xPlayer)
    local entry = jailed[xPlayer.identifier]
    if not entry or not Config.Jail.TeleportOnJoin then
        return
    end

    entry.source = src

    -- Un attimo perche' il personaggio finisca di caricarsi.
    SetTimeout(4000, function()
        if jailed[xPlayer.identifier] then
            sendToCell(src, GetCellById(entry.cell), entry)
        end
    end)
end)

--- Salvataggio del tempo residuo alla disconnessione: nessun secondo regalato.
AddEventHandler('playerDropped', function()
    local xPlayer = Framework.GetPlayer(source)
    if not xPlayer then
        return
    end

    local entry = jailed[xPlayer.identifier]
    if entry then
        entry.source = nil
        Database.Update('UPDATE kf_police_jail SET seconds_remaining = ? WHERE identifier = ?', {
            entry.seconds, xPlayer.identifier,
        })
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for identifier, entry in pairs(jailed) do
        Database.Update('UPDATE kf_police_jail SET seconds_remaining = ? WHERE identifier = ?', {
            entry.seconds, identifier,
        })
    end
end)
