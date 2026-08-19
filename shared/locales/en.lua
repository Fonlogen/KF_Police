Locales = Locales or {}

Locales['en'] = {
    -- Access
    not_allowed_job = 'You do not have the required job to open the tablet',
    no_permission = 'Your rank is not authorised for this action',
    no_player = 'Invalid player',
    rate_limited = 'Too many requests, wait a moment',
    mdt_opened = 'MDT opened',
    mdt_not_ready = 'The database is not ready yet',
    off_duty_read_only = 'Off duty the tablet is read only',

    -- Data
    invalid_data = 'Invalid data',
    citizen_not_found = 'Citizen not found',
    vehicle_not_found = 'Vehicle not found',
    report_not_found = 'Report not found',
    charge_not_found = 'Charge not found',
    note_not_found = 'Note not found',
    article_not_found = 'Article not found',

    -- Reports
    report_created = 'Report created',
    report_create_failed = 'Unable to create the report',
    report_updated = 'Report updated',
    report_deleted = 'Report deleted',

    -- Charges
    charge_added = 'Charge added to the file',
    charges_added = '%d charges added to the file',
    charge_add_failed = 'Unable to add the charge',
    charge_voided = 'Charge voided',
    charge_already_voided = 'Charge is already voided',

    -- Wanted and notes
    wanted_updated = 'Wanted status updated',
    note_saved = 'Note saved',
    note_deleted = 'Note deleted',

    -- Vehicles
    vehicle_updated = 'Vehicle record updated',
    vehicle_impounded = 'Vehicle impounded',
    vehicle_released = 'Vehicle released',
    vehicle_marked_stolen = 'Vehicle flagged as stolen',
    vehicle_not_impounded = 'Vehicle is not impounded',
    plate_check = 'Plate %s: %s',
    plate_unknown = 'Plate not found in records',

    -- Penal code and tags
    article_saved = 'Article saved',
    article_deleted = 'Article deleted',
    tag_saved = 'Tag saved',

    -- Fines
    fine_issued = 'Fine of $%s issued',
    fine_failed = 'Unable to issue the fine',
    fine_invalid_amount = 'Invalid amount',

    -- Radio
    radio_disabled = 'Radio is disabled',
    radio_no_item = 'You do not have a radio',
    radio_not_allowed = 'You cannot access this channel',
    radio_connected = 'Connected to radio channel',
    radio_disconnected = 'Disconnected from radio channel',
    radio_unavailable = 'Voice system unavailable',

    -- Duty
    duty_on = 'You are now on duty',
    duty_off = 'You are now off duty',
    duty_full = 'Maximum number of officers on duty reached',
    duty_required = 'You must be on duty',

    -- Cloakroom
    cloakroom = 'Cloakroom',
    cloakroom_uniform = 'Put on the uniform',
    cloakroom_civilian = 'Back to civilian clothes',
    uniform_applied = 'Uniform equipped',
    uniform_removed = 'Civilian clothes restored',
    uniform_missing = 'No uniform configured for your rank',

    -- Armory
    armory = 'Armory',
    armory_take = 'Take',
    armory_store = 'Store',
    armory_buy = 'Restock',
    armory_out_of_stock = 'Out of stock',
    armory_taken = '%s taken',
    armory_stored = '%s stored',
    armory_bought = '%s purchased',
    armory_no_money = 'Insufficient society funds',
    armory_no_item = 'You do not have this item',
    armory_full = 'No inventory space',

    -- Garage
    garage = 'Service garage',
    garage_spawn = 'Take out a vehicle',
    garage_store = 'Return the vehicle',
    garage_no_space = 'No free spot, move the vehicles',
    garage_already_out = 'You already have a service vehicle out',
    garage_stored = 'Vehicle returned',
    garage_not_service_vehicle = 'This is not a service vehicle',
    garage_no_vehicles = 'No vehicle available for your rank',

    -- Boss
    boss_menu = 'Society management',
    boss_unavailable = 'Society management unavailable',

    -- Field actions
    no_nearby_player = 'No nearby citizen',
    no_nearby_vehicle = 'No nearby vehicle',
    too_far = 'You are too far away',
    cuffed = 'You have been handcuffed',
    uncuffed = 'You have been released',
    cuff_target = 'Citizen handcuffed',
    uncuff_target = 'Citizen released',
    cuff_no_item = 'You need handcuffs',
    cuff_already = 'Citizen is already handcuffed',
    drag_start = 'You are escorting the citizen',
    drag_stop = 'You released the citizen',
    drag_need_cuffs = 'The citizen must be handcuffed',
    put_in_vehicle = 'Citizen put in the vehicle',
    out_of_vehicle = 'Citizen taken out of the vehicle',
    vehicle_no_seat = 'No free seat in the vehicle',
    search_done = 'Search completed',
    search_need_restraint = 'The citizen must be handcuffed or unconscious',
    searched = 'You have been searched',
    identity_shown = 'Documents shown',
    license_revoked = 'License %s revoked',
    license_granted = 'License %s granted',
    license_none = 'The citizen has no licenses',
    lockpick_success = 'Vehicle unlocked',
    lockpick_failed = 'Attempt failed',
    lockpick_no_item = 'You need a lockpick',
    object_placed = 'Object placed',
    object_removed = 'Object removed',
    object_none = 'No object nearby',

    -- Jail
    jail_sent = 'Citizen jailed for %s',
    jail_received = 'You have been jailed for %s',
    jail_released = 'Citizen released',
    jail_release_self = 'You have been released',
    jail_time_left = 'Time remaining: %s',
    jail_no_cell = 'No cell available',
    jail_already = 'Citizen is already in jail',
    jail_not_jailed = 'Citizen is not in jail',
    jail_disabled = 'Jail system disabled',
    jail_cannot_leave = 'You cannot leave the cell area',

    -- Progress
    progress_impound = 'Impounding...',
    progress_lockpick = 'Lockpicking...',
    progress_search = 'Searching...',
    progress_cuff = 'Applying handcuffs...',
}

Config.Locales = Locales
