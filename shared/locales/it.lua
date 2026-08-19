Locales = Locales or {}

Locales['it'] = {
    -- Accesso
    not_allowed_job = 'Non hai il lavoro necessario per aprire il tablet',
    no_permission = 'Il tuo grado non ti autorizza a questa operazione',
    no_player = 'Giocatore non valido',
    rate_limited = 'Troppe richieste, attendi qualche istante',
    mdt_opened = 'MDT aperto',
    mdt_not_ready = 'Il database non e ancora pronto',
    off_duty_read_only = 'Fuori servizio il tablet e in sola lettura',

    -- Dati
    invalid_data = 'Dati non validi',
    citizen_not_found = 'Cittadino non trovato',
    vehicle_not_found = 'Veicolo non trovato',
    report_not_found = 'Rapporto non trovato',
    charge_not_found = 'Reato non trovato',
    note_not_found = 'Nota non trovata',
    article_not_found = 'Articolo non trovato',

    -- Rapporti
    report_created = 'Rapporto creato',
    report_create_failed = 'Impossibile creare il rapporto',
    report_updated = 'Rapporto aggiornato',
    report_deleted = 'Rapporto eliminato',

    -- Reati
    charge_added = 'Reato aggiunto al fascicolo',
    charges_added = '%d reati aggiunti al fascicolo',
    charge_add_failed = 'Impossibile aggiungere il reato',
    charge_voided = 'Reato annullato',
    charge_already_voided = 'Il reato risulta gia annullato',

    -- Ricercati e note
    wanted_updated = 'Stato ricercato aggiornato',
    note_saved = 'Nota salvata',
    note_deleted = 'Nota eliminata',

    -- Veicoli
    vehicle_updated = 'Scheda veicolo aggiornata',
    vehicle_impounded = 'Veicolo sequestrato',
    vehicle_released = 'Veicolo dissequestrato',
    vehicle_marked_stolen = 'Veicolo segnalato come rubato',
    vehicle_not_impounded = 'Il veicolo non risulta sequestrato',
    plate_check = 'Targa %s: %s',
    plate_unknown = 'Targa non presente in archivio',

    -- Codice penale e tag
    article_saved = 'Articolo salvato',
    article_deleted = 'Articolo eliminato',
    tag_saved = 'Tag salvato',

    -- Multe
    fine_issued = 'Multa di $%s emessa',
    fine_failed = 'Impossibile emettere la multa',
    fine_invalid_amount = 'Importo non valido',

    -- Radio
    radio_disabled = 'Radio disabilitata',
    radio_no_item = 'Non hai una radio',
    radio_not_allowed = 'Non puoi accedere a questo canale',
    radio_connected = 'Connesso al canale radio',
    radio_disconnected = 'Disconnesso dal canale radio',
    radio_unavailable = 'Sistema voce non disponibile',

    -- Servizio
    duty_on = 'Sei entrato in servizio',
    duty_off = 'Sei uscito dal servizio',
    duty_full = 'Numero massimo di agenti in servizio raggiunto',
    duty_required = 'Devi essere in servizio',

    -- Spogliatoio
    cloakroom = 'Spogliatoio',
    cloakroom_uniform = 'Indossa la divisa',
    cloakroom_civilian = 'Torna in borghese',
    uniform_applied = 'Divisa indossata',
    uniform_removed = 'Abiti civili ripristinati',
    uniform_missing = 'Nessuna divisa configurata per il tuo grado',

    -- Armeria
    armory = 'Armeria',
    armory_take = 'Prendi',
    armory_store = 'Deposita',
    armory_buy = 'Rifornisci',
    armory_out_of_stock = 'Scorte esaurite',
    armory_taken = '%s prelevato',
    armory_stored = '%s depositato',
    armory_bought = '%s acquistato',
    armory_no_money = 'Fondi societa insufficienti',
    armory_no_item = 'Non hai questo oggetto',
    armory_full = 'Non hai spazio in inventario',

    -- Garage
    garage = 'Garage di servizio',
    garage_spawn = 'Preleva veicolo',
    garage_store = 'Riconsegna veicolo',
    garage_no_space = 'Nessun posto libero, sposta i veicoli',
    garage_already_out = 'Hai gia un veicolo di servizio in uso',
    garage_stored = 'Veicolo riconsegnato',
    garage_not_service_vehicle = 'Questo non e un veicolo di servizio',
    garage_no_vehicles = 'Nessun veicolo disponibile per il tuo grado',

    -- Boss
    boss_menu = 'Gestione societa',
    boss_unavailable = 'Gestione societa non disponibile',

    -- Azioni di campo
    no_nearby_player = 'Nessun cittadino vicino',
    no_nearby_vehicle = 'Nessun veicolo vicino',
    too_far = 'Sei troppo lontano',
    cuffed = 'Sei stato ammanettato',
    uncuffed = 'Sei stato slegato',
    cuff_target = 'Cittadino ammanettato',
    uncuff_target = 'Cittadino slegato',
    cuff_no_item = 'Ti servono le manette',
    cuff_already = 'Il cittadino e gia ammanettato',
    drag_start = 'Stai scortando il cittadino',
    drag_stop = 'Hai lasciato il cittadino',
    drag_need_cuffs = 'Il cittadino deve essere ammanettato',
    put_in_vehicle = 'Cittadino caricato sul veicolo',
    out_of_vehicle = 'Cittadino fatto scendere',
    vehicle_no_seat = 'Nessun posto libero sul veicolo',
    search_done = 'Perquisizione effettuata',
    search_need_restraint = 'Il cittadino deve essere ammanettato o incosciente',
    searched = 'Sei stato perquisito',
    identity_shown = 'Documenti mostrati',
    license_revoked = 'Licenza %s revocata',
    license_granted = 'Licenza %s rilasciata',
    license_none = 'Il cittadino non ha licenze',
    lockpick_success = 'Veicolo aperto',
    lockpick_failed = 'Tentativo fallito',
    lockpick_no_item = 'Ti serve un lockpick',
    object_placed = 'Oggetto piazzato',
    object_removed = 'Oggetto rimosso',
    object_none = 'Nessun oggetto nelle vicinanze',

    -- Carcere
    jail_sent = 'Cittadino trasferito in cella per %s',
    jail_received = 'Sei stato incarcerato per %s',
    jail_released = 'Cittadino rilasciato',
    jail_release_self = 'Sei stato rilasciato',
    jail_time_left = 'Tempo residuo: %s',
    jail_no_cell = 'Nessuna cella disponibile',
    jail_already = 'Il cittadino e gia in cella',
    jail_not_jailed = 'Il cittadino non e in cella',
    jail_disabled = 'Sistema carcerario disabilitato',
    jail_cannot_leave = 'Non puoi allontanarti dalla cella',

    -- Progressi
    progress_impound = 'Sequestro in corso...',
    progress_lockpick = 'Scasso in corso...',
    progress_search = 'Perquisizione in corso...',
    progress_cuff = 'Applicazione manette...',
}

Config.Locales = Locales
