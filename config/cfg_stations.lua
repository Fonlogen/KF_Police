--[[
    KF_Police - Stazioni, zone e punti di interazione
    ----------------------------------------------------------------------------
    Ogni punto viene registrato dal bridge `modules/target`: con ox_target
    diventa una zona sferica, con il fallback diventa un marker classico.
]]

Config.Stations = {
    LSPD = {
        label = 'Mission Row',
        blip = {
            coords = vector3(425.1, -979.5, 30.7),
            sprite = 60,
            display = 4,
            scale = 0.9,
            colour = 29,
        },

        --- Spogliatoi: divisa per grado e sesso (vedi cfg_duty.lua).
        cloakrooms = {
            vector3(452.6, -992.8, 30.6),
        },

        --- Armerie: prelievo, deposito e acquisto (vedi cfg_armory.lua).
        armories = {
            vector3(451.7, -980.1, 30.6),
        },

        --- Garage veicoli di servizio (vedi cfg_vehicles.lua).
        garages = {
            {
                spawner = vector3(454.6, -1017.4, 28.4),
                category = 'car',
                spawnPoints = {
                    { coords = vector3(438.4, -1018.3, 27.7), heading = 90.0 },
                    { coords = vector3(441.0, -1024.2, 28.3), heading = 90.0 },
                    { coords = vector3(453.5, -1022.2, 28.0), heading = 90.0 },
                    { coords = vector3(450.9, -1016.5, 28.1), heading = 90.0 },
                },
            },
            {
                spawner = vector3(461.1, -981.5, 43.6),
                category = 'helicopter',
                spawnPoints = {
                    { coords = vector3(449.5, -981.2, 43.6), heading = 92.6 },
                },
            },
        },

        --- Punto di riconsegna: parcheggiando qui il veicolo di servizio rientra.
        vehicleReturns = {
            { coords = vector3(462.0, -1014.4, 28.0), radius = 6.0 },
        },

        --- Menu societa' (esx_society oppure menu interno).
        bossActions = {
            vector3(448.4, -973.2, 30.6),
        },

        --- Deposito veicoli sequestrati.
        impound = {
            retrieve = vector3(408.6, -1637.0, 29.3),
            spawn = { coords = vector3(400.1, -1631.5, 29.3), heading = 228.0 },
        },
    },
}

--- Configurazione del bridge marker (usato quando Config.Target = 'marker').
Config.Marker = {
    drawDistance = 10.0,
    type = { cloakroom = 20, armory = 21, boss = 22, garage = 36, jail = 21 },
    size = vector3(1.5, 1.5, 0.5),
    color = { r = 168, g = 50, b = 42, a = 120 },
}

--- Raggio delle zone ox_target.
Config.TargetRadius = 1.2

--- Blip dei colleghi in servizio.
Config.ColleagueBlips = {
    Enabled = true,
    OnlyOnDuty = true,
    Refresh = 5000,
    sprite = 1,
    colour = 38,
    scale = 0.75,
}
