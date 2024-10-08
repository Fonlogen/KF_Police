Config = {}

Config.Debug = false

Config.Locale = "it"
Config.Locales = {} -- Edit locales in shared/locales

-- SETUP
Config.AutoDatabaseCreation = true

-- NUI Related
Config.window = {
	height = 768,
	width = 1080,
}

Config.borderImage = {
	widthOffset = 100,
	heightOffset = 150,
}

---------------------

Config.AllowedJobs = {
	["police"] = true,	
	["ambulance"] = true,
}

Config.NotificationsDuration = 3000

Config.EnabledPages = {    
	'citizen_search',
	'vehicle_search',
	'reports',
	'penal_code',
	-- 'agent_management',
	-- 'notice_board',
	'wanted_list',
}
