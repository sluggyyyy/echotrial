fx_version 'cerulean'
game 'gta5'
description 'Laundry System'
version '1.0.0'

client_scripts {
    'client/initmachines.lua'
}

server_scripts {
    'server/processlaundry.lua'
}

files {
    'stream/washing_closed.ydr',
    'stream/washing_closed.ytyp',
    'stream/washing_open.ydr',
    'stream/washing_open.ytyp',
    
    'html/bubbles.html',
    'html/dist/bubble-minigame.js',
    
    'html/washing_start.ogg',
    'html/washing.ogg'
}
ui_page 'html/bubbles.html'
data_file 'DLC_ITYP_REQUEST' 'stream/washing_closed.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/washing_open.ytyp'