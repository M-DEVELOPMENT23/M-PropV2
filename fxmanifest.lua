fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'M-DEVELOPMENT'
description 'Advanced Prop Creator for FiveM with Gizmo, Persistence and ox_target integration.'
version '2.0.0'
repository 'https://github.com/M-DEVELOPMENT23/M-PropV2' 

dependencies {
    'oxmysql',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    'configuration/config.lua'
}

client_scripts {
    'modules/client/**/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/server/**/*.lua'
}

exports {
    'useGizmo'
}

files {
    'locales/*.json',
    'configuration/config.lua'
}