local currentChannelId = nil
local radioReady = false

local function radioCfg()
    return Config.Radio or {}
end

local function callVoiceExport(exportCfg, ...)
    if not exportCfg or not exportCfg.resource or not exportCfg.name then
        return false
    end
    if GetResourceState(exportCfg.resource) ~= 'started' then
        return false
    end

    local ok = pcall(function(...)
        exports[exportCfg.resource][exportCfg.name](...)
    end, ...)
    return ok
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

    PlaySoundFrontend(-1, sound.dict or 'Click_Special', sound.name or 'WEB_NAVIGATION_SOUNDS_PHONE', true)
end

local function getPlayerJob()
    local player = ESX.GetPlayerData() or {}
    local job = player.job or {}
    return job.name, tonumber(job.grade) or 0
end

local function canUseChannel(channel)
    local jobName, grade = getPlayerJob()
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

    local player = ESX.GetPlayerData() or {}
    for _, item in pairs(player.inventory or {}) do
        if item.name == cfg.Item and (item.count or 0) > 0 then
            return true
        end
    end
    return false
end

function GetAvailableRadioChannels()
    local list = {}
    for _, channel in ipairs(radioCfg().Channels or {}) do
        if canUseChannel(channel) then
            list[#list + 1] = {
                id = channel.id,
                label = channel.label,
                channel = channel.channel,
                color = channel.color,
                connected = currentChannelId == channel.id,
            }
        end
    end
    return list
end

function GetRadioState()
    return {
        enabled = radioCfg().Enabled == true,
        current = currentChannelId,
        channels = GetAvailableRadioChannels(),
        volume = radioCfg().DefaultVolume or 60,
    }
end

function LeavePoliceRadio()
    local cfg = radioCfg()
    if not cfg.Enabled then
        return
    end

    callVoiceExport(cfg.Exports and cfg.Exports.leave)
    currentChannelId = nil
    playRadioSound('Disconnect')
end

function JoinPoliceRadio(channelId)
    local cfg = radioCfg()
    if not cfg.Enabled then
        return false, 'radio_disabled'
    end

    if not hasRadioItem() then
        return false, 'radio_no_item'
    end

    local selected = nil
    for _, channel in ipairs(cfg.Channels or {}) do
        if channel.id == channelId then
            selected = channel
            break
        end
    end

    if not selected or not canUseChannel(selected) then
        return false, 'radio_not_allowed'
    end

    if currentChannelId == selected.id then
        LeavePoliceRadio()
        return true, 'radio_disconnected'
    end

    if not radioReady then
        callVoiceExport(cfg.Exports and cfg.Exports.setProperty, 'radioEnabled', true)
        callVoiceExport(cfg.Exports and cfg.Exports.setVolume, cfg.DefaultVolume or 60)
        radioReady = true
    end

    callVoiceExport(cfg.Exports and cfg.Exports.setChannel, selected.channel)
    currentChannelId = selected.id
    playRadioSound('Connect')
    return true, 'radio_connected'
end

RegisterNUICallback('getRadioState', function(_, cb)
    cb(GetRadioState())
end)

RegisterNUICallback('toggleRadioChannel', function(data, cb)
    local ok, message = JoinPoliceRadio(data and data.id)
    if message then
        ESX.ShowNotification(Locale(message), ok and 'success' or 'error', Config.NotificationsDuration)
    end
    cb({
        ok = ok == true,
        message = message,
        state = GetRadioState(),
    })
end)

RegisterNUICallback('leaveRadio', function(_, cb)
    LeavePoliceRadio()
    cb({ ok = true, state = GetRadioState() })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        LeavePoliceRadio()
    end
end)
