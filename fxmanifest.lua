fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Fonlogen, Kekko'
description 'KF_Police - MDT e job polizia standalone (assorbe esx_policejob)'
version '2.0.0'

--[[
    L'ordine dei file e' esplicito e non usa glob: la configurazione deve essere
    caricata prima delle utilita', le utilita' prima dei permessi, i permessi
    prima di chi li usa. Un glob renderebbe l'ordine dipendente dal filesystem.
]]

shared_scripts {
    '@ox_lib/init.lua',

    -- Configurazione
    'config/config.lua',
    'config/cfg_stations.lua',
    'config/cfg_duty.lua',
    'config/cfg_armory.lua',
    'config/cfg_vehicles.lua',
    'config/cfg_actions.lua',
    'config/cfg_radio.lua',
    'config/cfg_jail.lua',
    'config/cfg_banking.lua',

    -- Utilita' e permessi
    'shared/sh_utils.lua',
    'shared/sh_permissions.lua',
    'shared/locales/en.lua',
    'shared/locales/it.lua',

    -- Contratto del bridge framework
    'modules/framework/sh_bridge.lua',
}

client_scripts {
    -- Bridge
    'modules/framework/cl_esx.lua',
    'modules/notify/cl_notify.lua',
    'modules/target/cl_ox.lua',
    'modules/target/cl_marker.lua',
    'modules/clothing/cl_appearance.lua',
    'modules/clothing/cl_skinchanger.lua',
    'modules/voice/cl_pma.lua',

    -- Nucleo
    'client/cl_main.lua',
    'client/cl_nui.lua',

    -- Funzioni
    'client/cl_duty.lua',
    'client/cl_cloakroom.lua',
    'client/cl_armory.lua',
    'client/cl_garage.lua',
    'client/cl_boss.lua',
    'client/cl_cuffs.lua',
    'client/cl_drag.lua',
    'client/cl_jail.lua',
    'client/cl_impound.lua',
    'client/cl_objects.lua',
    'client/cl_actions_citizen.lua',
    'client/cl_actions_vehicle.lua',
    'client/cl_radio.lua',
    'client/cl_blips.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    -- Bridge
    'modules/framework/sv_esx.lua',
    'modules/inventory/sv_ox.lua',
    'modules/inventory/sv_esx.lua',

    -- Infrastruttura: logger e permessi prima di chi li usa,
    -- migrazioni prima del database che le esegue.
    'server/sv_logger.lua',
    'server/sv_permissions.lua',
    'server/sv_migrations.lua',
    'server/sv_database.lua',

    -- Nucleo (registra il dispatcher degli endpoint)
    'server/sv_main.lua',

    -- Dominio
    'server/sv_citizens.lua',
    'server/sv_charges.lua',
    'server/sv_notes.lua',
    'server/sv_wanted.lua',
    'server/sv_reports.lua',
    'server/sv_vehicles.lua',
    'server/sv_penalcode.lua',
    'server/sv_duty.lua',
    'server/sv_jail.lua',
    'server/sv_fines.lua',
    'server/sv_armory.lua',
    'server/sv_garage.lua',
    'server/sv_actions.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/assets/**/*',
    -- I font sono nella risorsa: la NUI non ha accesso di rete garantito,
    -- quindi Google Fonts via CDN non e' affidabile (sezione 3.1).
    'web/assets/fonts/*.woff2',
    'web/assets/*.png',
    'sql/install.sql',
    'sql/seed.sql',
    'sql/migrations/*.sql',
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib',
}
