--[[
    KF_Police - Bridge voce: pma-voice (client)
    ----------------------------------------------------------------------------
    CORREZIONE BUG L1
    ----------------------------------------------------------------------------
    In FiveM il metatable degli export espone `function(self, ...)`: chiamare
    `exports[res][name](arg)` fa finire `arg` dentro `self` e la funzione riceve
    nil. Il vecchio client/cl_radio.lua faceva esattamente questo, quindi
    setRadioChannel veniva chiamato senza canale e la radio non cambiava mai.
    Qui il self viene passato esplicitamente: equivale a `exports[res]:name(...)`.
]]

Voice = {}

--- Stato dei presenti sul canale, ricavato dagli eventi di pma-voice.
local listeners = {}
local talking = {}

--- @return boolean ok
function Voice.CallExport(exportCfg, ...)
    if not exportCfg or not exportCfg.resource or not exportCfg.name then
        return false
    end

    if GetResourceState(exportCfg.resource) ~= 'started' then
        return false
    end

    local handle = exports[exportCfg.resource]
    if not handle then
        return false
    end

    local args = table.pack(...)
    local ok, err = pcall(function()
        -- self esplicito: identico a exports[resource]:name(...)
        return handle[exportCfg.name](handle, table.unpack(args, 1, args.n))
    end)

    if not ok and Config.Debug then
        print(('[KF_Police] Export %s:%s fallito: %s'):format(exportCfg.resource, exportCfg.name, tostring(err)))
    end

    return ok
end

function Voice.Available()
    local cfg = Config.Radio or {}
    return cfg.Enabled == true and GetResourceState(cfg.Resource or 'pma-voice') == 'started'
end

function Voice.SetChannel(channel)
    return Voice.CallExport(Config.Radio.Exports.setChannel, tonumber(channel) or 0)
end

function Voice.Leave()
    listeners = {}
    talking = {}
    return Voice.CallExport(Config.Radio.Exports.leave)
end

function Voice.SetVolume(volume)
    return Voice.CallExport(Config.Radio.Exports.setVolume, ClampInt(volume, 0, 100, 60))
end

function Voice.SetRadioEnabled(enabled)
    return Voice.CallExport(Config.Radio.Exports.setProperty, 'radioEnabled', enabled == true)
end

--- Numero di persone in ascolto sul canale corrente (compreso l'agente).
function Voice.GetListenerCount()
    local count = 0
    for _ in pairs(listeners) do
        count = count + 1
    end
    return count + 1
end

--- Id server di chi sta parlando adesso.
function Voice.GetTalking()
    local list = {}
    for source in pairs(talking) do
        list[#list + 1] = source
    end
    return list
end

function Voice.IsAnyoneTalking()
    return next(talking) ~= nil
end

--- Notifica al resto della risorsa che lo stato radio e' cambiato.
local function broadcastState()
    TriggerEvent('KF_Police:Client:RadioStateChanged')
end

RegisterNetEvent('pma-voice:syncRadioData', function(radioTable)
    listeners = {}
    talking = {}

    for source, isTalking in pairs(radioTable or {}) do
        listeners[source] = true
        if isTalking then
            talking[source] = true
        end
    end

    broadcastState()
end)

RegisterNetEvent('pma-voice:addPlayerToRadio', function(plySource)
    if plySource then
        listeners[plySource] = true
        broadcastState()
    end
end)

RegisterNetEvent('pma-voice:removePlayerFromRadio', function(plySource)
    if plySource then
        listeners[plySource] = nil
        talking[plySource] = nil
        broadcastState()
    end
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio', function(plySource, enabled)
    if not plySource then
        return
    end

    if enabled then
        talking[plySource] = true
    else
        talking[plySource] = nil
    end

    broadcastState()
end)
