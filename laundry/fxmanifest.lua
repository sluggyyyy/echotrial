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