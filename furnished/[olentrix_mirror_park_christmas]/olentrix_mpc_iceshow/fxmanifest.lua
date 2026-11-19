fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_iceshow'
author 'Olentrix Assets'
description 'Mirror Park Christmas: an ice skating show on the rink, started by any player'
version '1.5.0'

dependency 'olentrix_mpc_skatekit'

shared_scripts { 'config.lua', 'routine.lua' }
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/audio/*.ogg' }
