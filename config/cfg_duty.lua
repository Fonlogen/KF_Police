--[[
    KF_Police - Servizio e divise
    ----------------------------------------------------------------------------
    Il servizio e' interno (tabella kf_police_duty_log): nessuna dipendenza da
    esx_service. Le divise sono indicizzate per nome del grado in job_grades.
]]

Config.Duty = {
    --- Se true un agente fuori servizio non compare nei blip ne' nel roster.
    Enabled = true,

    --- Entra in servizio automaticamente al primo caricamento del personaggio.
    AutoOnLoad = false,

    --- Fuori servizio il MDT resta consultabile in sola lettura.
    ReadOnlyOffDuty = true,

    --- Numero massimo di agenti in servizio contemporaneamente (-1 = illimitato).
    MaxInService = -1,
}

--- Abbigliamento civile: viene salvato all'ingresso in servizio e ripristinato
--- all'uscita, in modo che lo spogliatoio non distrugga il vestiario personale.
Config.Cloakroom = {
    RestoreCivilian = true,
    --- Voci aggiuntive dello spogliatoio, oltre alla divisa del grado.
    Extras = {
        { id = 'bulletproof', label = 'Giubbotto antiproiettile', icon = 'shield' },
        { id = 'gilet', label = 'Gilet alta visibilita', icon = 'shield' },
    },
}

--[[
    Divise. Le chiavi di primo livello sono i `name` dei gradi in `job_grades`
    (recruit / officer / sergeant / lieutenant / boss), piu' le voci speciali
    `bulletproof` e `gilet` usate dagli Extras.
]]
Config.Uniforms = {
    recruit = {
        male = {
            tshirt_1 = 59, tshirt_2 = 1,
            torso_1 = 55, torso_2 = 0,
            decals_1 = 0, decals_2 = 0,
            arms = 41,
            pants_1 = 25, pants_2 = 0,
            shoes_1 = 25, shoes_2 = 0,
            helmet_1 = 46, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
        female = {
            tshirt_1 = 36, tshirt_2 = 1,
            torso_1 = 48, torso_2 = 0,
            decals_1 = 0, decals_2 = 0,
            arms = 44,
            pants_1 = 34, pants_2 = 0,
            shoes_1 = 27, shoes_2 = 0,
            helmet_1 = 45, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
    },

    officer = {
        male = {
            tshirt_1 = 58, tshirt_2 = 0,
            torso_1 = 55, torso_2 = 0,
            decals_1 = 0, decals_2 = 0,
            arms = 41,
            pants_1 = 25, pants_2 = 0,
            shoes_1 = 25, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
        female = {
            tshirt_1 = 35, tshirt_2 = 0,
            torso_1 = 48, torso_2 = 0,
            decals_1 = 0, decals_2 = 0,
            arms = 44,
            pants_1 = 34, pants_2 = 0,
            shoes_1 = 27, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
    },

    sergeant = {
        male = {
            tshirt_1 = 58, tshirt_2 = 0,
            torso_1 = 55, torso_2 = 0,
            decals_1 = 8, decals_2 = 1,
            arms = 41,
            pants_1 = 25, pants_2 = 0,
            shoes_1 = 25, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
        female = {
            tshirt_1 = 35, tshirt_2 = 0,
            torso_1 = 48, torso_2 = 0,
            decals_1 = 7, decals_2 = 1,
            arms = 44,
            pants_1 = 34, pants_2 = 0,
            shoes_1 = 27, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
    },

    lieutenant = {
        male = {
            tshirt_1 = 58, tshirt_2 = 0,
            torso_1 = 55, torso_2 = 0,
            decals_1 = 8, decals_2 = 2,
            arms = 41,
            pants_1 = 25, pants_2 = 0,
            shoes_1 = 25, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
        female = {
            tshirt_1 = 35, tshirt_2 = 0,
            torso_1 = 48, torso_2 = 0,
            decals_1 = 7, decals_2 = 2,
            arms = 44,
            pants_1 = 34, pants_2 = 0,
            shoes_1 = 27, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
    },

    boss = {
        male = {
            tshirt_1 = 58, tshirt_2 = 0,
            torso_1 = 55, torso_2 = 0,
            decals_1 = 8, decals_2 = 3,
            arms = 41,
            pants_1 = 25, pants_2 = 0,
            shoes_1 = 25, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
        female = {
            tshirt_1 = 35, tshirt_2 = 0,
            torso_1 = 48, torso_2 = 0,
            decals_1 = 7, decals_2 = 3,
            arms = 44,
            pants_1 = 34, pants_2 = 0,
            shoes_1 = 27, shoes_2 = 0,
            helmet_1 = -1, helmet_2 = 0,
            chain_1 = 0, chain_2 = 0,
            ears_1 = 2, ears_2 = 0,
        },
    },

    bulletproof = {
        male = { bproof_1 = 11, bproof_2 = 1 },
        female = { bproof_1 = 13, bproof_2 = 1 },
    },

    gilet = {
        male = { tshirt_1 = 59, tshirt_2 = 1 },
        female = { tshirt_1 = 36, tshirt_2 = 1 },
    },
}
