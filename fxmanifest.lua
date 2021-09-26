fx_version 'adamant'

game 'gta5'

description 'Rawe Admin Menu'

version '1.0.0'

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/*.lua'
}

shared_script {
    'config.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/index.js',
    'html/index.css',
    'html/img/logo.png'

}