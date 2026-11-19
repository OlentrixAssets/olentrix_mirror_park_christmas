fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_elf'
author 'Olentrix Assets'
description 'Mirror Park Christmas: the naughty or nice elf'
version '2.0.1'

this_is_a_map 'yes'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'
files { 'spots.json', 'html/index.html', 'html/audio/*.ogg', 'xe_lair_tc.xml' }

data_file 'TIMECYCLEMOD_FILE' 'xe_lair_tc.xml'
data_file 'DLC_ITYP_REQUEST' 'stream/xe_lair.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xe_candycane.ytyp'
