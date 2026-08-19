--[[
    KF_Police - Azioni di campo
    ----------------------------------------------------------------------------
    Voci del menu contestuale su cittadino e veicolo, piu' gli oggetti
    piazzabili. Ogni azione dichiara il permesso richiesto: se il grado non lo
    ha, la voce non viene nemmeno mostrata (e il server la rifiuta comunque).
]]

Config.Actions = {
    --- Distanza massima per agire su un altro giocatore.
    MaxDistance = 2.5,

    --- Distanza massima per agire su un veicolo.
    MaxVehicleDistance = 4.0,

    --- Item necessario per ammanettare (vuoto = nessun item richiesto).
    HandcuffItem = 'handcuffs',

    --- Durata delle manette in ms (0 = fino allo slega manuale).
    HandcuffTimer = 10 * 60 * 1000,

    --- Item per il lockpick dei veicoli.
    LockpickItem = 'lockpick',

    --- Il cittadino deve essere ammanettato o incosciente per essere perquisito.
    SearchRequiresRestraint = true,
}

--- Voci del menu contestuale su un cittadino.
Config.CitizenActions = {
    { id = 'identity',  label = 'Carta d\'identita',   icon = 'identity', permission = 'field.identify' },
    { id = 'cuff',      label = 'Ammanetta / slega',   icon = 'jail',     permission = 'field.cuff' },
    { id = 'drag',      label = 'Scorta',              icon = 'jail',     permission = 'field.cuff' },
    { id = 'vehicle',   label = 'Metti / togli dal veicolo', icon = 'vehicles', permission = 'field.cuff' },
    { id = 'search',    label = 'Perquisisci',         icon = 'search',   permission = 'field.search' },
    { id = 'fine',      label = 'Multa',               icon = 'charge',   permission = 'field.fine' },
    { id = 'licenses',  label = 'Licenze',             icon = 'identity', permission = 'field.license' },
    { id = 'jail',      label = 'Porta in cella',      icon = 'jail',     permission = 'jail.send' },
}

--- Voci del menu contestuale su un veicolo.
Config.VehicleActions = {
    { id = 'plate',     label = 'Controlla targa',  icon = 'vehicles', permission = 'mdt.view' },
    { id = 'lockpick',  label = 'Scassina',         icon = 'evidence', permission = 'field.lockpick' },
    { id = 'impound',   label = 'Sequestra',        icon = 'vehicles', permission = 'field.impound' },
    { id = 'stolen',    label = 'Segnala rubato',   icon = 'warning',  permission = 'mdt.vehicle.flag' },
    { id = 'search',    label = 'Perquisisci',      icon = 'search',   permission = 'field.search' },
}

--- Oggetti piazzabili. `item` vuoto = nessun item consumato.
Config.PlaceableObjects = {
    { id = 'cone',    label = 'Cono',           model = 'prop_roadcone02a',      item = '' },
    { id = 'barrier', label = 'Barriera',       model = 'prop_barrier_work05',   item = '' },
    { id = 'spikes',  label = 'Chiodi',         model = 'p_ld_stinger_s',        item = '', spikes = true },
    { id = 'tape',    label = 'Nastro',         model = 'prop_police_do_not_cross', item = '' },
    { id = 'light',   label = 'Faro',           model = 'prop_worklight_03b',    item = '' },
}

--- Durata massima di un oggetto piazzato prima della rimozione automatica (ms).
Config.PlaceableLifetime = 60 * 60 * 1000

--- Sequestro veicolo.
Config.Impound = {
    --- Prezzo di riscatto pagato dal proprietario.
    Fee = 500,
    --- Durata dell'animazione di sequestro (ms).
    Duration = 8000,
}
