--[[
    KF_Police - Configurazione generale
    ----------------------------------------------------------------------------
    Questo file contiene solo le impostazioni trasversali. Tutto il resto e'
    suddiviso nei file cfg_*.lua della stessa cartella, caricati subito dopo.
]]

Config = {}

-- ============================================================================
--  Base
-- ============================================================================

Config.Debug = false

Config.Locale = 'it'
Config.Locales = {}

--- Framework di riferimento. Attualmente disponibile: 'esx'.
Config.Framework = 'esx'

--- Bridge interazioni in gioco: 'ox_target' oppure 'marker'.
Config.Target = 'ox_target'

--- Bridge inventario: 'ox_inventory' oppure 'esx'.
Config.Inventory = 'ox_inventory'

--- Bridge vestiario: 'fivem-appearance' oppure 'skinchanger'.
Config.Clothing = 'fivem-appearance'

--- Lavori autorizzati ad aprire il MDT.
Config.AllowedJobs = {
    ['police'] = true,
    ['ambulance'] = true,
}

--- Lavoro considerato "polizia" per le funzioni di campo (manette, sequestro...).
Config.PoliceJobs = {
    ['police'] = true,
}

--- Societa' usata per fatturazione e conti.
Config.Society = 'society_police'

-- ============================================================================
--  Apertura del MDT
-- ============================================================================

Config.OpenCommand = 'openmdt'

--- F5 e non F6: F6 collide con `police:quickactions` di esx_policejob (bug L8).
Config.OpenKey = 'F5'

--- Item che apre il tablet (ox_inventory). Vuoto per disabilitare.
Config.OpenItem = 'police_mdt'

--- Item alternativi accettati (retrocompatibilita' con gli inventari esistenti).
Config.OpenItemAliases = { 'mdt', 'tablet' }

Config.NotificationsDuration = 3000

-- ============================================================================
--  Interfaccia: scala dinamica
-- ============================================================================
--[[
    Il tablet non ha piu' una dimensione assoluta in pixel: l'altezza e' una
    frazione dello schermo, la larghezza deriva dal rapporto di progetto e la
    radice CSS viene scalata di conseguenza. Cosi' a 1080p, 1440p e 4K il testo
    ha la stessa dimensione apparente.
]]
Config.UI = {
    baseWidth   = 1280,  -- larghezza logica di progetto (il mockup)
    baseHeight  = 910,   -- rapporto 1.4066
    heightRatio = 0.86,  -- frazione dell'altezza schermo occupata dal tablet
    minWidth    = 1080,  -- non scende sotto
    maxWidth    = 1920,  -- non sale sopra
    scale       = 1.0,   -- zoom utente: 0.9 | 1.0 | 1.1
}

--- Pagine abilitate, nell'ordine in cui compaiono nella sidebar.
--- Le chiavi corrispondono a `PAGES` in web/src/pages/registry.ts.
Config.EnabledPages = {
    'citizens',
    'vehicles',
    'reports',
    'penalcode',
    'wanted',
    'jail',
    'radio',
    'duty',
}

--- Dimensione di pagina predefinita per le liste del MDT.
Config.PageSize = 25
Config.MaxPageSize = 100

--- Foto segnaletica di riserva: file locale, nessun host esterno.
Config.DefaultImage = 'assets/guest.png'

-- ============================================================================
--  Anti-abuso
-- ============================================================================

--- Numero massimo di callback MDT per giocatore nella finestra indicata.
Config.RateLimit = {
    Enabled = true,
    Window = 10000, -- ms
    MaxCalls = 120,
    MaxWrites = 30,
}

--- Lunghezze massime accettate dai callback (validazione lato server).
Config.Limits = {
    query = 64,
    note = 1000,
    reportTitle = 120,
    reportBody = 8000,
    reason = 255,
    location = 128,
    plate = 12,
    penalTitle = 160,
    penalDescription = 2000,
}

--- Tracciamento su kf_police_audit.
Config.Audit = {
    Enabled = true,
    KeepDays = 60,
}
