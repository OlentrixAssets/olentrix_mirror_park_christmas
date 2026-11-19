fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_legion_coaster'
author 'Olentrix Assets'
description 'Mirror Park Christmas: the Legion Plunge coaster under Legion Square'
version '2.0.0'

this_is_a_map 'yes'

dependencies {
    'olentrix_mpc_market',
    'olentrix_mpc_coaster'
}

data_file 'DLC_ITYP_REQUEST' 'stream/lg_lch_climb.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lch_drop.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lch_loop1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lch_loop2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_00.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_01.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_02.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_03.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_04.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_05.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_06.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_07.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_08.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_09.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_10.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_11.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_12.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_13.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_14.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_15.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_16.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_17.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_18.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_19.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_20.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_21.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_22.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lcs_23.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lst_in.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lst_out.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/lg_lwin.ytyp'

client_scripts { 'audio.lua', 'client.lua' }
server_script 'server.lua'

ui_page 'html/index.html'
files { 'ride.json', 'html/index.html', 'html/audio/*.ogg' }
