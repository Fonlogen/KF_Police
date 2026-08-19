ESX = exports['es_extended']:getSharedObject()

opened = false
CurrentData = {}

local function notify(message, nType)
    ESX.ShowNotification(message, nType or 'info', Config.NotificationsDuration)
end

local function getPlayerJobName()
    local player = ESX.GetPlayerData()
    return player and player.job and player.job.name or nil
end

function CanOpenMDT()
    if not ESX.IsPlayerLoaded() then
        return false
    end

    return Config.AllowedJobs[getPlayerJobName()] == true
end

function BuildPlayerNuiData(profile)
    local player = ESX.GetPlayerData() or {}
    local job = player.job or {}

    return {
        firstName = (profile and profile.firstName) or player.firstName or '',
        lastName = (profile and profile.lastName) or player.lastName or '',
        grade = (profile and profile.grade) or job.grade_label or '',
        job = (profile and profile.job) or job.name or '',
        job_label = (profile and profile.job_label) or job.label or '',
        citizenId = profile and profile.citizenId or player.ssn or player.identifier,
        image = (profile and profile.image) or Config.DefaultImage,
        identifier = player.identifier,
    }
end

function RequestDataUpdate()
    local result = lib.callback.await('KF_Police:Server:GetData', false) or {}
    CurrentData = result
    UpdateStartNuiData()
    return result
end

function UpdateStartNuiData()
    UpdateNuiPlayerData()
    UpdateNuiConfigData()
    UpdateNuiTheme()
    UpdateNuiEnabledPages()
    UpdateNuiData()
end

function UpdateNuiEnabledPages()
    SendNUIMessage({
        action = 'setEnabledPages',
        data = Config.EnabledPages
    })
end

function UpdateNuiData()
    SendNUIMessage({
        action = 'setData',
        data = CurrentData
    })
end

function UpdateNuiPlayerData()
    local profile = lib.callback.await('KF_Police:Server:GetPlayerProfile', false) or {}
    SendNUIMessage({
        action = 'setPlayerData',
        data = BuildPlayerNuiData(profile)
    })
end

function UpdateNuiConfigData()
    SendNUIMessage({
        action = 'setConfig',
        data = {
            window = Config.window,
            borderImage = Config.borderImage,
            Debug = Config.Debug,
            EnabledPages = Config.EnabledPages,
            Locale = Config.Locale,
            DefaultTown = Config.DefaultTown,
            DefaultImage = Config.DefaultImage,
            Radio = {
                Enabled = Config.Radio and Config.Radio.Enabled,
                Channels = (GetAvailableRadioChannels and GetAvailableRadioChannels()) or {},
            },
        }
    })
end

function UpdateNuiTheme()
    local jobName = getPlayerJobName()
    if Config.AllowedJobs[jobName] then
        SendNUIMessage({
            action = 'setTheme',
            data = jobName
        })
    end
end

function CloseMDT()
    if not opened then
        SetNuiFocus(false, false)
        return
    end

    SendNUIMessage({
        action = 'open',
        data = {
            visible = false
        }
    })

    opened = false
    SetNuiFocus(false, false)
end

function OpenMDT()
    if not ESX.IsPlayerLoaded() then
        return
    end

    if not CanOpenMDT() then
        return notify(Locale('not_allowed_job'), 'error')
    end

    if opened then
        return CloseMDT()
    end

    opened = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        data = {
            visible = true
        }
    })

    CreateThread(function()
        RequestDataUpdate()
    end)
end

RegisterCommand(Config.OpenCommand or 'openmdt', function()
    OpenMDT()
end, false)

if Config.OpenKey and Config.OpenKey ~= '' then
    RegisterKeyMapping(Config.OpenCommand or 'openmdt', 'Apri MDT Polizia', 'keyboard', Config.OpenKey)
end

RegisterNetEvent('esx:setJob', function(job)
    if opened and not Config.AllowedJobs[job.name] then
        CloseMDT()
        return
    end

    if Config.AllowedJobs[job.name] then
        UpdateNuiPlayerData()
        UpdateNuiTheme()
    end
end)

RegisterNetEvent('KF_Police:Client:OpenMDT', function()
    OpenMDT()
end)
