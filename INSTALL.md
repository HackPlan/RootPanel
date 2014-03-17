## Ubuntu 13.10

    add-apt-repository ppa:chris-lea/node.js
    apt-get update
    
    apt-get install nodejs git mongodb memcached
    npm install pm2 -g
    
    git clone https://github.com/jysperm/RootPanel.git
    cd RootPanel
    
    gulp less coffee
    pm2 start app.coffee
