fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_coaster'
author 'Olentrix Assets'
description 'Mirror Park Christmas: the Sleigh Run coaster'
version '1.0.0'

dependency 'olentrix_mpc_market'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_cst_car.ytyp'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'
files { 'ride.json', 'html/index.html', 'html/audio/*.ogg' }
