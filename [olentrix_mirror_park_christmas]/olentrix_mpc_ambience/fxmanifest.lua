fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_ambience'
author 'Olentrix Assets'
description 'Mirror Park Christmas: ambience and light ceremony'
version '1.1.0'

dependency 'olentrix_mpc_market'
shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/audio/*.ogg' }
