fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_cutscene'
author 'Olentrix Assets'
description 'Mirror Park Christmas: the intro cutscene, a camera tour timed to the song'
version '2.0.1'

shared_scripts { 'config.lua', 'data.lua' }
client_script 'client.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/audio/*.mp3' }
