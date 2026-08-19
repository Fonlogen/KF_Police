Config = {}

Config.Debug = false

Config.Locale = "it"
Config.Locales = {}

Config.AutoDatabaseCreation = true

Config.OpenCommand = "openmdt"
Config.OpenKey = "F6"
Config.OpenItem = "mdt"

Config.window = {
	height = 768,
	width = 1080,
}

Config.borderImage = {
	widthOffset = 100,
	heightOffset = 150,
}

Config.AllowedJobs = {
	["police"] = true,
	["ambulance"] = true,
}

Config.NotificationsDuration = 3000

Config.EnabledPages = {
	"citizen_search",
	"vehicle_search",
	"reports",
	"penal_code",
	"wanted_list",
}

Config.DefaultTown = "Los Santos"
Config.DefaultImage = "https://via.placeholder.com/150.jpg"

Config.UseBilling = true
Config.BillingSociety = "society_police"

--[[
	Banking / billing adapters.
	Tutti gli export ed eventi sono configurabili.
	Il primo adapter il cui resource è started viene usato (ordine = priorità).
]]
Config.Banking = {
	Enabled = true,
	FallbackLabel = "Sanzione polizia",
	Society = "society_police",
	AccountType = "bank",
	Reason = "police_fine",

	Adapters = {
		{
			name = "esx_billing",
			resource = "esx_billing",
			export = {
				resource = "esx_billing",
				name = "BillPlayerByIdentifier",
				args = { "targetIdentifier", "officerIdentifier", "society", "label", "amount" },
			},
		},
		{
			name = "okokBilling",
			resource = "okokBilling",
			export = {
				resource = "okokBilling",
				name = "CreateCustomInvoice",
				args = { "targetSource", "amount", "label", "societyLabel", "society", "society" },
			},
		},
		{
			name = "okokBanking",
			resource = "okokBanking",
			export = {
				resource = "okokBanking",
				name = "AddTransaction",
				args = { "targetIdentifier", "society", "amount", "label", "reason" },
			},
			event = {
				name = "okokBanking:AddNewTransaction",
				type = "server",
				args = { "targetIdentifier", "society", "amount", "label" },
			},
		},
		{
			name = "qb-banking",
			resource = "qb-banking",
			export = {
				resource = "qb-banking",
				name = "CreateFine",
				args = { "targetSource", "amount", "label", "society" },
			},
		},
		{
			name = "Renewed-Banking",
			resource = "Renewed-Banking",
			export = {
				resource = "Renewed-Banking",
				name = "handleTransaction",
				args = { "targetIdentifier", "label", "amount", "label", "society", "targetIdentifier", "withdraw" },
			},
		},
		{
			name = "fd_banking",
			resource = "fd_banking",
			export = {
				resource = "fd_banking",
				name = "AddTransaction",
				args = { "targetIdentifier", "amount", "label", "reason" },
			},
		},
		{
			name = "tgg-banking",
			resource = "tgg-banking",
			export = {
				resource = "tgg-banking",
				name = "AddTransaction",
				args = { "targetIdentifier", "amount", "label" },
			},
		},
		{
			name = "codem-bank",
			resource = "codem-bank",
			event = {
				name = "codem-bank:server:addTransaction",
				type = "server",
				args = { "targetIdentifier", "amount", "label" },
			},
		},
		{
			name = "qs-banking",
			resource = "qs-banking",
			export = {
				resource = "qs-banking",
				name = "AddTransaction",
				args = { "targetIdentifier", "amount", "label" },
			},
		},
	},
}

--[[
	Radio PMA-VOICE (stile Origen Police).
	channel = frequenza numerica pma-voice
]]
Config.Radio = {
	Enabled = true,
	Resource = "pma-voice",
	RequireItem = false,
	Item = "radio",
	DefaultVolume = 60,
	DisconnectOnClose = false,
	UseAnims = true,

	Exports = {
		setChannel = { resource = "pma-voice", name = "setRadioChannel" },
		leave = { resource = "pma-voice", name = "removePlayerFromRadio" },
		setVolume = { resource = "pma-voice", name = "setRadioVolume" },
		setProperty = { resource = "pma-voice", name = "setVoiceProperty" },
	},

	Sounds = {
		Enabled = true,
		Connect = { dict = "Click_Special", name = "WEB_NAVIGATION_SOUNDS_PHONE", volume = 0.35 },
		Disconnect = { dict = "Click_Fail", name = "WEB_NAVIGATION_SOUNDS_PHONE", volume = 0.35 },
		Click = { dict = "Click_Special", name = "WEB_NAVIGATION_SOUNDS_PHONE", volume = 0.2 },
	},

	Channels = {
		{
			id = "lspd_main",
			label = "LSPD Principale",
			channel = 1,
			color = "#2788c9",
			jobs = { "police" },
			minGrade = 0,
		},
		{
			id = "lspd_tac",
			label = "LSPD Tattica",
			channel = 2,
			color = "#1a5f8a",
			jobs = { "police" },
			minGrade = 2,
		},
		{
			id = "lspd_cmd",
			label = "LSPD Comando",
			channel = 3,
			color = "#0d3b57",
			jobs = { "police" },
			minGrade = 4,
		},
		{
			id = "ems_main",
			label = "EMS Principale",
			channel = 4,
			color = "#e74c3c",
			jobs = { "ambulance" },
			minGrade = 0,
		},
		{
			id = "shared",
			label = "Canale Condiviso",
			channel = 5,
			color = "#27ae60",
			jobs = { "police", "ambulance" },
			minGrade = 0,
		},
	},
}
