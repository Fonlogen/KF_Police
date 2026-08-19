--[[
    KF_Police - Veicoli di servizio
    ----------------------------------------------------------------------------
    Nessuna dipendenza da esx_vehicleshop (su questo server e' in [disabled]):
    i veicoli sono spawnati direttamente dal garage, targati `LSPD` + numero e
    non vengono salvati in owned_vehicles.
]]

Config.Garage = {
    --- Prefisso targa dei veicoli di servizio.
    PlatePrefix = 'LSPD',

    --- Un solo veicolo di servizio per agente alla volta.
    OneVehiclePerOfficer = true,

    --- Elimina il veicolo quando l'agente esce dal servizio o si disconnette.
    DespawnOnDuty = true,

    --- Rifornisce e ripara il veicolo allo spawn.
    SpawnFullFuel = true,

    --- Livrea/extra applicati a tutti i veicoli di servizio.
    DefaultProps = {
        modLivery = 0,
    },
}

--[[
    Veicoli autorizzati per categoria e nome del grado.
    `price` = 0 significa gratuito (di servizio); un prezzo > 0 viene scalato
    dal conto societa'.
]]
Config.AuthorizedVehicles = {
    car = {
        recruit = {
            { model = 'police', label = 'Cruiser', price = 0 },
        },
        officer = {
            { model = 'police', label = 'Cruiser', price = 0 },
            { model = 'police3', label = 'Interceptor', price = 0 },
        },
        sergeant = {
            { model = 'police', label = 'Cruiser', price = 0 },
            { model = 'police3', label = 'Interceptor', price = 0 },
            { model = 'policet', label = 'Furgone trasporto', price = 0 },
            { model = 'policeb', label = 'Motocicletta', price = 0 },
        },
        lieutenant = {
            { model = 'police', label = 'Cruiser', price = 0 },
            { model = 'police3', label = 'Interceptor', price = 0 },
            { model = 'policet', label = 'Furgone trasporto', price = 0 },
            { model = 'policeb', label = 'Motocicletta', price = 0 },
            { model = 'riot', label = 'Riot', price = 0 },
            { model = 'fbi2', label = 'SUV non contrassegnato', price = 0 },
        },
        boss = {
            { model = 'police', label = 'Cruiser', price = 0 },
            { model = 'police3', label = 'Interceptor', price = 0 },
            { model = 'policet', label = 'Furgone trasporto', price = 0 },
            { model = 'policeb', label = 'Motocicletta', price = 0 },
            { model = 'riot', label = 'Riot', price = 0 },
            { model = 'fbi2', label = 'SUV non contrassegnato', price = 0 },
        },
    },

    helicopter = {
        recruit = {},
        officer = {},
        sergeant = {},
        lieutenant = {
            { model = 'polmav', label = 'Maverick', price = 0, props = { modLivery = 0 } },
        },
        boss = {
            { model = 'polmav', label = 'Maverick', price = 0, props = { modLivery = 0 } },
        },
    },
}
