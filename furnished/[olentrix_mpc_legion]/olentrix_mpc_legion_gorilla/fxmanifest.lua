fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_legion_gorilla'
author 'Olentrix Assets'
description 'Mirror Park Christmas: Legion Square grate gorilla'
version '2.0.0'

this_is_a_map 'yes'

shared_scripts {
    'config.lua',
    'timing.lua'
}
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/audio/*.ogg', 'lg_gor_tc.xml' }

data_file 'TIMECYCLEMOD_FILE' 'lg_gor_tc.xml'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_plate.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_well.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_pit.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_head.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_jaw.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_uarml.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_uarmr.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_farml.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_gor_farmr.ytyp'
