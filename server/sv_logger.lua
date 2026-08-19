--[[
    KF_Police - Tracciabilita' (kf_police_audit)
    ----------------------------------------------------------------------------
    Ogni scrittura sensibile lascia una riga. Serve a due cose: ricostruire chi
    ha fatto cosa dopo una segnalazione, e accorgersi di un exploit guardando la
    frequenza delle azioni di un singolo identifier.
]]

Logger = {}

local queue = {}
local FLUSH_INTERVAL = 2000
local MAX_BATCH = 50

function Logger.Info(message, ...)
    print(('[KF_Police] ' .. message):format(...))
end

function Logger.Warn(message, ...)
    print(('^3[KF_Police] ' .. message .. '^7'):format(...))
end

function Logger.Error(message, ...)
    print(('^1[KF_Police] ' .. message .. '^7'):format(...))
end

function Logger.Debug(message, ...)
    if Config.Debug then
        print(('^5[KF_Police:debug] ' .. message .. '^7'):format(...))
    end
end

--- Registra un'azione. La scrittura e' accodata e svuotata in lotti, cosi'
--- l'audit non aggiunge latenza al callback che lo ha generato.
--- @param actor table|string|nil xPlayer, identifier oppure nil (sistema)
--- @param action string es. 'charge.add'
--- @param target string|nil bersaglio (identifier, targa, id rapporto)
--- @param payload table|nil dati aggiuntivi
function Logger.Audit(actor, action, target, payload)
    if not Config.Audit or not Config.Audit.Enabled then
        return
    end

    local identifier, name

    if type(actor) == 'table' then
        identifier = actor.identifier
        name = Framework.GetName(actor)
    elseif type(actor) == 'string' then
        identifier = actor
    end

    queue[#queue + 1] = {
        identifier,
        name,
        tostring(action):sub(1, 64),
        target and tostring(target):sub(1, 128) or nil,
        payload and json.encode(payload) or nil,
    }

    if #queue >= MAX_BATCH then
        Logger.Flush()
    end
end

function Logger.Flush()
    if #queue == 0 then
        return
    end

    local batch = queue
    queue = {}

    local statements = {}
    for _, entry in ipairs(batch) do
        statements[#statements + 1] = {
            'INSERT INTO kf_police_audit (actor_identifier, actor_name, action, target, payload) VALUES (?, ?, ?, ?, ?)',
            entry,
        }
    end

    Database.Transaction(statements)
end

--- Elenco per il pannello di controllo (permesso mdt.audit.view).
function Logger.List(filters)
    filters = filters or {}

    local where, params = {}, {}

    if filters.actor then
        where[#where + 1] = 'actor_identifier = ?'
        params[#params + 1] = filters.actor
    end
    if filters.action then
        where[#where + 1] = 'action LIKE ?'
        params[#params + 1] = '%' .. filters.action .. '%'
    end

    local clause = #where > 0 and (' WHERE ' .. table.concat(where, ' AND ')) or ''
    local limit = ClampInt(filters.limit, 1, 200, 50)

    return Database.Query(([[
        SELECT id, actor_identifier, actor_name, action, target, payload, at
        FROM kf_police_audit%s
        ORDER BY at DESC
        LIMIT %d
    ]]):format(clause, limit), params) or {}
end

CreateThread(function()
    while true do
        Wait(FLUSH_INTERVAL)
        Logger.Flush()
    end
end)

--- Pulizia periodica: l'audit non deve crescere all'infinito.
CreateThread(function()
    Wait(30000)

    while true do
        if Config.Audit and Config.Audit.Enabled and (Config.Audit.KeepDays or 0) > 0 then
            Database.Update('DELETE FROM kf_police_audit WHERE at < DATE_SUB(NOW(), INTERVAL ? DAY)', {
                ClampInt(Config.Audit.KeepDays, 1, 3650, 60),
            })
        end

        Wait(6 * 60 * 60 * 1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Logger.Flush()
    end
end)
