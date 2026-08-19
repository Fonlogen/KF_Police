--[[
    KF_Police - Armeria
    ----------------------------------------------------------------------------
    Lo stock e' su `kf_police_armory_stock` (non su esx_datastore). Il prelievo
    scala lo stock, il deposito lo rialza, l'acquisto lo crea addebitando la
    societa' o l'agente secondo `Config.Armory.BuyFrom`.
]]

Config.Armory = {
    --- 'society' scala il conto societa', 'player' addebita il contante dell'agente.
    BuyFrom = 'society',

    --- Grado minimo che puo' comprare (rifornire) l'armeria.
    BuyPermission = 'armory.buy',

    --- Registra ogni prelievo/deposito su kf_police_audit.
    Audit = true,

    --- Stock iniziale creato alla prima installazione.
    InitialStock = {
        WEAPON_NIGHTSTICK = 20,
        WEAPON_STUNGUN = 10,
        WEAPON_FLASHLIGHT = 20,
        WEAPON_APPISTOL = 8,
        WEAPON_ADVANCEDRIFLE = 4,
        WEAPON_PUMPSHOTGUN = 4,
        handcuffs = 25,
        radio = 25,
        police_mdt = 10,
        armor = 15,
    },
}

--[[
    Armi autorizzate per nome del grado. `components` sono gli hash dei
    componenti applicati al prelievo (ox_inventory li accetta come metadata).
]]
Config.AuthorizedWeapons = {
    recruit = {
        { weapon = 'WEAPON_NIGHTSTICK', price = 0 },
        { weapon = 'WEAPON_FLASHLIGHT', price = 80 },
        { weapon = 'WEAPON_STUNGUN', price = 1500 },
        { weapon = 'WEAPON_APPISTOL', price = 10000, components = { 0, 0, 1000, 4000 } },
    },

    officer = {
        { weapon = 'WEAPON_NIGHTSTICK', price = 0 },
        { weapon = 'WEAPON_FLASHLIGHT', price = 0 },
        { weapon = 'WEAPON_STUNGUN', price = 500 },
        { weapon = 'WEAPON_APPISTOL', price = 10000, components = { 0, 0, 1000, 4000 } },
        { weapon = 'WEAPON_ADVANCEDRIFLE', price = 50000, components = { 0, 6000, 1000, 4000, 8000 } },
    },

    sergeant = {
        { weapon = 'WEAPON_NIGHTSTICK', price = 0 },
        { weapon = 'WEAPON_FLASHLIGHT', price = 0 },
        { weapon = 'WEAPON_STUNGUN', price = 500 },
        { weapon = 'WEAPON_APPISTOL', price = 10000, components = { 0, 0, 1000, 4000 } },
        { weapon = 'WEAPON_ADVANCEDRIFLE', price = 50000, components = { 0, 6000, 1000, 4000, 8000 } },
        { weapon = 'WEAPON_PUMPSHOTGUN', price = 70000, components = { 2000, 6000 } },
    },

    lieutenant = {
        { weapon = 'WEAPON_NIGHTSTICK', price = 0 },
        { weapon = 'WEAPON_FLASHLIGHT', price = 0 },
        { weapon = 'WEAPON_STUNGUN', price = 500 },
        { weapon = 'WEAPON_APPISTOL', price = 10000, components = { 0, 0, 1000, 4000 } },
        { weapon = 'WEAPON_ADVANCEDRIFLE', price = 50000, components = { 0, 6000, 1000, 4000, 8000 } },
        { weapon = 'WEAPON_PUMPSHOTGUN', price = 70000, components = { 2000, 6000 } },
    },

    boss = {
        { weapon = 'WEAPON_NIGHTSTICK', price = 0 },
        { weapon = 'WEAPON_FLASHLIGHT', price = 0 },
        { weapon = 'WEAPON_STUNGUN', price = 500 },
        { weapon = 'WEAPON_APPISTOL', price = 10000, components = { 0, 0, 1000, 4000 } },
        { weapon = 'WEAPON_ADVANCEDRIFLE', price = 50000, components = { 0, 6000, 1000, 4000, 8000 } },
        { weapon = 'WEAPON_PUMPSHOTGUN', price = 70000, components = { 2000, 6000 } },
    },
}

--- Oggetti (non armi) prelevabili dall'armeria, per tutti i gradi.
Config.ArmoryItems = {
    { item = 'handcuffs', label = 'Manette', price = 0, max = 2 },
    { item = 'radio', label = 'Radio', price = 0, max = 1 },
    { item = 'police_mdt', label = 'Tablet MDT', price = 0, max = 1 },
    { item = 'armor', label = 'Giubbotto', price = 0, max = 1 },
}
