## Ubuntu 14.04 amd64

    apt-get install python-software-properties software-properties-common
    add-apt-repository ppa:chris-lea/node.js
    apt-get update
    apt-get upgrade

    apt-get install nodejs git mongodb memcached nginx python g++ make
    npm install pm2 gulp -g

    adduser rpadmin
    usermod -G rpadmin -a www-data
    su rpadmin
    cd ~

    git clone https://github.com/jysperm/RootPanel.git
    cd RootPanel

    vi core/config.coffee

    npm install

    rm /etc/nginx/sites-enabled/default
    cat > /etc/nginx/sites-available/rpadmin

    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;

        server_name DOMAIN;

        location / {
            proxy_pass http://unix:/home/rpadmin/rootpanel.sock:/;
        }
    }

    ln -s /etc/nginx/sites-available/rpadmin /etc/nginx/sites-enabled
    service nginx restart
