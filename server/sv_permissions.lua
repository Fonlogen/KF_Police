--[[
    KF_Police - Validazione dei permessi lato server
    ----------------------------------------------------------------------------
    CORREZIONE BUG L12
    ----------------------------------------------------------------------------
    Prima nessun callback controllava il grado: qualunque agente `police` poteva
    marcare ricercati, cancellare rapporti o sequestrare. Da qui in avanti ogni
    callback passa da `RequirePermission`, che rivalida nell'ordine:
      1. il giocatore esiste
      2. il lavoro e' autorizzato
      3. il grado ha il permesso
      4. il rate limit non e' saturo
    Il payload della NUI non e' mai considerato attendibile.
]]

--- Contatori del rate limit, per source.
local rateState = {}

local function rateKey(src)
    return tostring(src)
end

--- @return boolean consentito
local function checkRateLimit(src, isWrite)
    local cfg = Config.RateLimit
    if not cfg or not cfg.Enabled then
        return true
    end

    local key = rateKey(src)
    local now = GetGameTimer()
    local state = rateState[key]

    if not state or now - state.since > cfg.Window then
        state = { since = now, calls = 0, writes = 0 }
        rateState[key] = state
    end

    state.calls = state.calls + 1
    if isWrite then
        state.writes = state.writes + 1
    end

    if state.calls > (cfg.MaxCalls or 120) then
        return false
    end

    if isWrite and state.writes > (cfg.MaxWrites or 30) then
        return false
    end

    return true
end

--- Il giocatore, se esiste e ha un lavoro autorizzato ad aprire il MDT.
--- @param src number
--- @return table|nil
function GetOfficer(src)
    local xPlayer = Framework.GetPlayer(src)
    if not xPlayer then
        return nil
    end

    local jobName = Framework.GetJob(xPlayer)
    if not IsAllowedJob(jobName) then
        return nil
    end

    return xPlayer
end

--- Validazione completa. Ritorna il giocatore solo se tutto e' in ordine.
--- @param src number
--- @param permission string|nil
--- @return table|nil xPlayer, string|nil motivo del rifiuto
function RequirePermission(src, permission)
    local xPlayer = Framework.GetPlayer(src)
    if not xPlayer then
        return nil, 'no_player'
    end

    local jobName, grade = Framework.GetJob(xPlayer)
    if not IsAllowedJob(jobName) then
        return nil, 'not_allowed_job'
    end

    local isWrite = permission ~= nil and Config.WritePermissions[permission] == true

    if not checkRateLimit(src, isWrite) then
        Logger.Warn('Rate limit superato da %s (%s)', xPlayer.identifier or src, tostring(permission))
        return nil, 'rate_limited'
    end

    if permission and not HasPermission(jobName, grade, permission) then
        Logger.Audit(xPlayer, 'permission.denied', permission, { job = jobName, grade = grade })
        return nil, 'no_permission'
    end

    return xPlayer, nil
end

--- Variante che notifica il giocatore in caso di rifiuto.
--- @return table|nil
function RequirePermissionNotify(src, permission)
    local xPlayer, reason = RequirePermission(src, permission)

    if not xPlayer and reason then
        Framework.Notify(src, Locale(reason), 'error')
    end

    return xPlayer
end

--- Descrittore dell'agente, riutilizzato in tutte le scritture.
--- @return table
function OfficerInfo(xPlayer)
    local jobName, grade, gradeName, gradeLabel = Framework.GetJob(xPlayer)

    return {
        identifier = xPlayer.identifier,
        name = Framework.GetName(xPlayer),
        job = jobName,
        grade = grade,
        gradeName = gradeName,
        gradeLabel = gradeLabel,
        ssn = Framework.GetSsn(xPlayer),
        source = xPlayer.source,
    }
end

AddEventHandler('playerDropped', function()
    rateState[rateKey(source)] = nil
end)
