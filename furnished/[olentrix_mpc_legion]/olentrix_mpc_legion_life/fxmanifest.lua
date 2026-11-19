fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'olentrix_mpc_legion_life'
author 'Olentrix Assets'
description 'Mirror Park Christmas: Legion Square snowball corner, plaza music and seats'
version '2.0.1'

dependencies {
    'olentrix_mpc_legion'
}

shared_script 'data.lua'

client_scripts {
    'client_common.lua',
    'client_snow.lua',
    'client_music.lua',
    'client_seats.lua'
}
server_script 'server.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/audio/*.ogg' }
