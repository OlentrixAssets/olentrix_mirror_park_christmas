fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_skating'
author 'Olentrix Assets'
description 'Mirror Park Christmas: buy ice skates and skate on the rink'
version '1.4.0'

dependency 'olentrix_mpc_skatekit'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/audio/*.ogg',
}
