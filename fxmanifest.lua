game 'gta5'
fx_version 'cerulean'
lua54 'yes'
use_experimental_fxv2_oal "yes"

shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
	'config.lua'
}

client_script 'client.lua'
server_script 'server.lua'

