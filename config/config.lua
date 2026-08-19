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
    heightRatio = 0.96,  -- frazione dell'altezza schermo occupata dal tablet
    minWidth    = 1080,  -- non scende sotto (misura la SCHERMATA, non la cornice)
    maxWidth    = 1920,  -- non sale sopra (idem)
    scale       = 1.0,   -- zoom utente: 0.9 | 1.0 | 1.1
}

--[[
    Cornice fisica del dispositivo: web/assets/tablet.png
    ----------------------------------------------------------------------------
    L'immagine ha una finestra trasparente al centro, ed e' quella la schermata
    utile: la UI ci va dentro, la scocca resta intorno.

    `heightRatio` misura la cornice INTERA, non la schermata. Siccome la scocca
    e' alta 1073/888 = 1.208 volte il ritaglio, la schermata utile e' sempre piu'
    piccola della frazione dichiarata: e' la ragione per cui `heightRatio` e'
    passato da 0.86 a 0.96 quando la cornice e' stata introdotta, altrimenti la
    UI si sarebbe rimpicciolita del 17% e il testo con lei.

    Le misure sotto sono rilevate dal PNG e vanno cambiate solo se si sostituisce
    l'immagine. Il rapporto del ritaglio (1280/888 = 1.441) non e' identico a
    quello di progetto (1280/910 = 1.407): la cornice viene quindi stirata del
    2.4% in verticale per far combaciare la finestra con la schermata. E'
    volontario e impercettibile; l'alternativa sarebbe deformare la UI o
    aggiungere bande nere.

    ATTENZIONE alle misure orizzontali: NON sono il ritaglio nudo.
    Il bordo della finestra e' antialiasato su esattamente 1 pixel (a x=60 e
    x=1337 l'alpha e' 54, cioe' trasparente al 79%). Siccome l'immagine viene
    stirata, l'arrotondamento sub-pixel lasciava quel pixel morbido senza UI
    dietro e in gioco si vedeva 1 px di gioco per lato. Quindi la finestra
    dichiarata parte dall'ultimo pixel COMPLETAMENTE opaco (x=59) e arriva
    all'ultimo opaco dall'altra parte (x=1338 escluso): 2 px in piu' del ritaglio
    reale, cioe' 1 px di sovrapposizione per lato. La colonna in piu' della UI
    finisce sotto la scocca nera, dove non si vede.

    In verticale la rampa e' identica (y=93 e y=980 hanno alpha 122) ma in gioco
    la cucitura non si nota: se dovesse comparire, la correzione e' la stessa,
    cutoutY = 92 e cutoutHeight = 890.

    `enabled = false` torna al telaio puramente CSS di prima; in quel caso
    conviene rimettere `heightRatio` a 0.86, altrimenti la schermata cresce del
    12% rispetto a come era progettata.
]]
Config.UI.frame = {
    enabled      = true,
    imageWidth   = 1400,  -- dimensione del PNG
    imageHeight  = 1073,
    cutoutX      = 59,    -- finestra + 1 px di sovrapposizione per lato
    cutoutY      = 93,
    cutoutWidth  = 1280,  -- ritaglio reale 1278, vedi nota sull'antialiasing
    cutoutHeight = 888,
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
