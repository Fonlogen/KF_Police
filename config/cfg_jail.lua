--[[
    KF_Police - Carcere
    ----------------------------------------------------------------------------
    Il tempo residuo vive su `kf_police_jail` (secondi) ed e' quindi persistente
    a disconnessione e restart. La conversione da mesi di condanna a secondi e'
    definita qui.
]]

Config.Jail = {
    Enabled = true,

    --- Secondi di detenzione per ogni "mese" del codice penale.
    SecondsPerMonth = 30,

    --- Tetto massimo di detenzione in secondi (2 ore reali).
    MaxSeconds = 2 * 60 * 60,

    --- Se true il timer scende anche a giocatore offline.
    CountOffline = false,

    --- Intervallo di aggiornamento del timer (secondi).
    Tick = 5,

    --- Ogni quanti tick si scrive su database.
    PersistEvery = 6,

    --- Il detenuto viene teleportato in cella a ogni rientro in gioco.
    TeleportOnJoin = true,

    --- Punto di rilascio.
    Release = vector3(1845.0, 2585.9, 45.7),

    --- Rimuove tutte le armi all'ingresso in cella.
    StripWeapons = true,

    --- Celle disponibili. `capacity` = detenuti per cella.
    Cells = {
        { id = 'A1', label = 'Cella A1', coords = vector3(1762.0, 2596.7, 45.6), capacity = 2 },
        { id = 'A2', label = 'Cella A2', coords = vector3(1762.0, 2591.6, 45.6), capacity = 2 },
        { id = 'A3', label = 'Cella A3', coords = vector3(1762.0, 2586.5, 45.6), capacity = 2 },
        { id = 'B1', label = 'Cella B1', coords = vector3(1780.7, 2596.7, 45.6), capacity = 2 },
        { id = 'B2', label = 'Cella B2', coords = vector3(1780.7, 2591.6, 45.6), capacity = 2 },
        { id = 'B3', label = 'Cella B3', coords = vector3(1780.7, 2586.5, 45.6), capacity = 2 },
    },

    --- Zona entro cui il detenuto e' confinato: uscirne lo riporta in cella.
    Bounds = {
        center = vector3(1771.0, 2591.0, 45.6),
        radius = 65.0,
    },
}
