fx_version 'cerulean'
game 'gta5'

description 'Laundry System'
version '1.0.0'

client_scripts {
    'client/client.lua',
    'client/initmachines.lua'
}

server_scripts {
    'server/inventory.lua',
    'server/processlaundry.lua'
}

files {
    'stream/washing_closed.ydr',
    'stream/washing_closed.ytyp',
    'stream/washing_open.ydr',
    'stream/washing_open.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/washing_closed.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/washing_open.ytyp'