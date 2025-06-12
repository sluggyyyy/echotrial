fx_version 'cerulean'
game 'gta5'
description 'Money Counter'
version '1.0.0'

client_scripts {
    'client/initcounter.lua'
}

server_scripts {
    'server/processcash.lua'
}

files {
    'html/audio.html',
    'html/dist/money-counter-audio.js',
    
    'html/beep.ogg',
    'html/money_counter.ogg'
}
ui_page 'html/audio.html'