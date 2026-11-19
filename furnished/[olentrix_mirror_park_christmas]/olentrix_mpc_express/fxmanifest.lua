fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_express'
author 'Olentrix Assets'
description 'Mirror Park Christmas: Christmas Express'
version '2.0.0'

dependency 'olentrix_mpc_market'
this_is_a_map 'yes'

shared_scripts { 'config.lua', 'rail_data.lua' }
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/audio/*.ogg' }

data_file 'DLC_ITYP_REQUEST' 'stream/xv_rbridge.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rstation.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_01.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_02.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_03.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_04.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_05.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_06.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_07.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_08.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_09.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_10.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_11.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_12.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_13.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_rtrack_14.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_xcoach.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_xloco.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/xv_xtender.ytyp'
