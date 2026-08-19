--[[
    KF_Police - Radio (client)
    ----------------------------------------------------------------------------
    Il pannello radio vive dentro al tablet (RadioDock nel telaio + pagina Radio):
    non c'e' piu' un overlay separato. La chiamata agli export di pma-voice passa
    da modules/voice/cl_pma.lua, che usa il colon-call corretto (bug L1).
]]

local currentChannelId = nil
local radioReady = false
local volume = nil

local function radioCfg()
    return Config.Radio or {}
end

local function playRadioSound(kind)
    local sounds = radioCfg().Sounds
    if not sounds or sounds.Enabled == false then
        return
    end

    local sound = sounds[kind]
    if not sound then
        return
    end

    PlaySoundFrontend(-1, sound.name or 'WEB_NAVIGATION_SOUNDS_PHONE', sound.dict or 'Click_Special', true)
end

--- Il canale e' accessibile al lavoro e al grado dell'agente?
local function canUseChannel(channel)
    local jobName, grade = Framework.GetJob()
    if not jobName then
        return false
    end

    local allowed = false
    for _, job in ipairs(channel.jobs or {}) do
        if job == jobName then
            allowed = true
            break
        end
    end

    if not allowed then
        return false
    end

    return grade >= (tonumber(channel.minGrade) or 0)
end

local function hasRadioItem()
    local cfg = radioCfg()
    if not cfg.RequireItem then
        return true
    end

    return Framework.HasItem(cfg.Item or 'radio', 1)
end

local function findChannel(channelId)
    for _, channel in ipairs(radioCfg().Channels or {}) do
        if channel.id == channelId then
            return channel
        end
    end

    return nil
end

--- Canali autorizzati per l'agente, con lo stato di connessione.
function GetAvailableRadioChannels()
    local list = {}

    for _, channel in ipairs(radioCfg().Channels or {}) do
        if canUseChannel(channel) then
            list[#list + 1] = {
                id = channel.id,
                label = channel.label,
                short = channel.short or ('CH%d'):format(channel.channel or 0),
                channel = channel.channel,
                connected = currentChannelId == channel.id,
            }
        end
    end

    return list
end

function GetRadioState()
    local channel = currentChannelId and findChannel(currentChannelId) or nil

    return {
        enabled = radioCfg().Enabled == true and Voice.Available(),
        current = currentChannelId,
        currentLabel = channel and channel.label or nil,
        currentNumber = channel and channel.channel or nil,
        channels = GetAvailableRadioChannels(),
        volume = volume or radioCfg().DefaultVolume or 60,
        listeners = currentChannelId and Voice.GetListenerCount() or 0,
        talking = currentChannelId and Voice.IsAnyoneTalking() or false,
    }
end

function PushRadioStateToNui()
    if not MdtIsOpen() then
        return
    end

    SendNUIMessage({
        action = 'mdt:radio',
        data = GetRadioState(),
    })
end

function LeavePoliceRadio()
    if not currentChannelId then
        return
    end

    Voice.Leave()
    currentChannelId = nil
    playRadioSound('Disconnect')
    PushRadioStateToNui()
end

--- @return boolean ok, string chiave del messaggio
function JoinPoliceRadio(channelId)
    local cfg = radioCfg()

    if not cfg.Enabled then
        return false, 'radio_disabled'
    end

    if not Voice.Available() then
        return false, 'radio_unavailable'
    end

    if not hasRadioItem() then
        return false, 'radio_no_item'
    end

    local selected = findChannel(channelId)
    if not selected or not canUseChannel(selected) then
        return false, 'radio_not_allowed'
    end

    if currentChannelId == selected.id then
        LeavePoliceRadio()
        return true, 'radio_disconnected'
    end

    if not radioReady then
        Voice.SetRadioEnabled(true)
        Voice.SetVolume(volume or cfg.DefaultVolume or 60)
        radioReady = true
    end

    if not Voice.SetChannel(selected.channel) then
        return false, 'radio_unavailable'
    end

    currentChannelId = selected.id
    playRadioSound('Connect')
    PushRadioStateToNui()

    return true, 'radio_connected'
end

-- ============================================================================
--  Endpoint locali del MDT (la radio e' interamente lato client)
-- ============================================================================

RegisterLocalMdtEndpoint('radio:state', function()
    return { ok = true, radio = GetRadioState() }
end)

RegisterLocalMdtEndpoint('radio:join', function(payload)
    local ok, message = JoinPoliceRadio(payload and payload.channelId)

    if message then
        Notify(Locale(message), ok and 'success' or 'error')
    end

    return { ok = ok, message = Locale(message or ''), radio = GetRadioState() }
end)

RegisterLocalMdtEndpoint('radio:leave', function()
    LeavePoliceRadio()
    return { ok = true, radio = GetRadioState() }
end)

RegisterLocalMdtEndpoint('radio:volume', function(payload)
    volume = ClampInt(payload and payload.volume, 0, 100, 60)
    Voice.SetVolume(volume)

    return { ok = true, radio = GetRadioState() }
end)

-- ============================================================================
--  Sincronizzazione
-- ============================================================================

--- Lo stato radio cambia anche per eventi esterni (qualcuno entra, qualcuno
--- parla): il dock si aggiorna senza che la NUI debba interrogare.
AddEventHandler('KF_Police:Client:RadioStateChanged', function()
    PushRadioStateToNui()
end)

RegisterNetEvent('KF_Police:Client:LeaveRadio', function()
    LeavePoliceRadio()
end)

RegisterNetEvent('esx:setJob', function(job)
    -- Cambiando lavoro il canale non e' piu' autorizzato.
    if currentChannelId and not IsAllowedJob(job and job.name) then
        LeavePoliceRadio()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        LeavePoliceRadio()
    end
end)
