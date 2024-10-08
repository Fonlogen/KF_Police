ESX = exports['es_extended']:getSharedObject()

opened = false

local CurrentData = {}

RegisterCommand('openmdt', function()
  OpenMDT()
end)

RegisterNUICallback('getClientData', function(data, cb)
	RequestDataUpdate()
end)

function RequestDataUpdate()
	-- Wait(500)
	local result = lib.callback.await('KF_Police:Server:GetData', false)
	for k, v in pairs(result) do
		CurrentData[k] = v
	end
	
	UpdateStartNuiData()
end

function UpdateStartNuiData(data)
	UpdateNuiPlayerData()
	UpdateNuiConfigData()
	UpdateNuiTheme()
	UpdateNuiData()
end

RegisterNUICallback('getEnabledPages', function(data, cb)
	Wait(500)
	UpdateNuiEnabledPages()
end)

function UpdateNuiEnabledPages()
	SendNUIMessage({
		action = "setEnabledPages",
		data = Config.EnabledPages
	})
end

function UpdateNuiData()
	SendNUIMessage({
		action = "setData",
		data = CurrentData
	})
end

function UpdateNuiPlayerData()
	print('Updating player data')
	local player = ESX.GetPlayerData()

	SendNUIMessage({
		action = "setPlayerData",
		data = player
	})
end

function UpdateNuiConfigData()
	local config = ESX.GetConfig()

	SendNUIMessage({
		action = "setConfig",
		data = Config
	})
end

function UpdateNuiTheme()
	if Config.AllowedJobs[ESX.GetPlayerData().job.name] then
		local theme = ESX.GetPlayerData().job.name

		SendNUIMessage({
			action = "setTheme",
			data = theme
		})
	end
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	print('Changed job to ' .. job.name)
	if Config.AllowedJobs[job.name] then
		UpdateNuiPlayerData()
		UpdateNuiTheme()
	end
end)

function OpenMDT()
	if not ESX.IsPlayerLoaded() then
		return
	end

	if not Config.AllowedJobs[ESX.GetPlayerData().job.name] then
		return ESX.ShowNotification(Locales[Config.Locale].not_allowed_job, "error", Config.NotificationsDuration)
	end

	print('Opening MDT')

	SendNUIMessage({
		action = "open",
		data = {
			visible = true
		}
	})

	opened = true

	SetNuiFocus(true, true)
end

RegisterNUICallback('close', function()
	SendNUIMessage({
		action = "open",
		data = {
			visible = false
		}
	})

	opened = false

	SetNuiFocus(false, false)
end)

RegisterNUICallback('createReport', function(data)
	local report = {
		title = data.title,
		description = data.description,
		tags = data.tags,
		involved = data.involved,
		involved_vehicles = data.involved_vehicles,
	}

	TriggerServerEvent('KF_Police:Server:CreateReport', report)
end)