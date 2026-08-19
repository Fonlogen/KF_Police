--[[
    KF_Police - Radio (pma-voice)
    ----------------------------------------------------------------------------
    `channel` e' la frequenza numerica pma-voice. `short` e' l'etichetta corta
    mostrata nei pulsanti del RadioDock in fondo al tablet.
]]

Config.Radio = {
    Enabled = true,
    Resource = 'pma-voice',

    --- Richiede l'item radio in inventario.
    RequireItem = false,
    Item = 'radio',

    DefaultVolume = 60,

    --- Esce dal canale quando il tablet viene chiuso.
    DisconnectOnClose = false,

    --- Esce dal canale quando l'agente smette il servizio o cambia lavoro.
    DisconnectOnDutyEnd = true,

    UseAnims = true,

    --- Export di pma-voice. Chiamati con il colon-call corretto (bug L1).
    Exports = {
        setChannel = { resource = 'pma-voice', name = 'setRadioChannel' },
        leave      = { resource = 'pma-voice', name = 'removePlayerFromRadio' },
        setVolume  = { resource = 'pma-voice', name = 'setRadioVolume' },
        setProperty = { resource = 'pma-voice', name = 'setVoiceProperty' },
    },

    Sounds = {
        Enabled = true,
        Connect = { dict = 'Click_Special', name = 'WEB_NAVIGATION_SOUNDS_PHONE', volume = 0.35 },
        Disconnect = { dict = 'Click_Fail', name = 'WEB_NAVIGATION_SOUNDS_PHONE', volume = 0.35 },
        Click = { dict = 'Click_Special', name = 'WEB_NAVIGATION_SOUNDS_PHONE', volume = 0.2 },
    },

    Channels = {
        {
            id = 'lspd_main',
            label = 'LSPD Principale',
            short = 'CH1',
            channel = 1,
            jobs = { 'police' },
            minGrade = 0,
        },
        {
            id = 'lspd_tac',
            label = 'LSPD Tattica',
            short = 'CH2',
            channel = 2,
            jobs = { 'police' },
            minGrade = 2,
        },
        {
            id = 'lspd_cmd',
            label = 'LSPD Comando',
            short = 'CH3',
            channel = 3,
            jobs = { 'police' },
            minGrade = 4,
        },
        {
            id = 'ems_main',
            label = 'EMS Principale',
            short = 'EMS',
            channel = 4,
            jobs = { 'ambulance' },
            minGrade = 0,
        },
        {
            id = 'shared',
            label = 'Canale Condiviso',
            short = 'TAC',
            channel = 5,
            jobs = { 'police', 'ambulance' },
            minGrade = 0,
        },
    },
}
