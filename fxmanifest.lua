fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Fonlogen, Kekko'
description 'Advanced Police MDT System'
version '1.0.0'

client_scripts {
  'client/**/*'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/**/*'
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/**/*',
}

ui_page 'web/build/index.html'

files {
  'web/build/index.html',
  'web/build/assets/**/*'
}

dependencies {
  'es_extended',
  'oxmysql',
  'ox_lib',
}