## Ubuntu 14.04 amd64
### Core

    apt-get install python-software-properties software-properties-common
    add-apt-repository ppa:chris-lea/node.js
    apt-get update
    apt-get upgrade

    vi /etc/hostname
    vi /etc/hosts

    apt-get install nodejs git mongodb nginx postfix redis-server
    apt-get install python g++ make screen git wget zip unzip iftop unrar-free axel vim emacs subversion subversion-tools curl tmux mercurial htop
    apt-get install libcurl4-openssl-dev
    apt-get install ntp quota quotatool

    mongo

        use admin
        db.addUser({user: 'rpadmin', pwd: 'password', roles: ['readWriteAnyDatabase', 'userAdminAnyDatabase', 'dbAdminAnyDatabase', 'clusterAdmin']})
        use RootPanel
        db.addUser({user: 'rpadmin', pwd: 'password', roles: ['readWrite']})

    vi /etc/mongodb.conf

        auth = true
        noprealloc = true
        smallfiles = true
        
    vi /etc/redis/redis.conf
        
        requirepass password

    rm /etc/nginx/sites-enabled/default
    
    cat > /etc/nginx/sites-available/rpadmin
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        rewrite ^/(.*)$ http://DOMAIN/#redirect permanent;
    }

    server {
        listen 80;

        server_name DOMAIN;

        location / {
            proxy_set_header X-Real-IP $remote_addr;
            proxy_pass http://unix:/home/rpadmin/rootpanel.sock:/;
        }
    }

    ln -s /etc/nginx/sites-available/rpadmin /etc/nginx/sites-enabled

    adduser rpadmin
    usermod -G rpadmin -a www-data

    vi /etc/sudoers

        rpadmin ALL=(ALL) NOPASSWD: ALL

    vi /etc/fstab

        usrquota

    reboot

    ln -s /dev/xvda /dev/root
    quotacheck -am
    quotaon -au

    su rpadmin
    cd ~

    git clone https://github.com/jysperm/RootPanel.git
    cd RootPanel

    chmod 750 config.coffee
    vi config.coffee

    make install
    make start
    
### Plugin

    # Memcached

    apt-get install memcached
    
    # MySQL
    
    apt-get install mariadb-server
    
    mysql -u root -p
    
        GRANT ALL ON *.* TO 'rpadmin'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
        
    # PHP-FPM
        
    apt-get install php5-cli php5-fpm php-pear php5-mysql php5-curl php5-gd php-pear php5-imap php5-mcrypt php5-memcache php5-tidy php5-xmlrpc php5-sqlite php5-mongo
    
    rm /etc/php5/fpm/pool.d/www.conf

    vi /etc/nginx/fastcgi_params
        
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

### Runtime

    apt-get install golang golang-go.tools

    apt-get install python python3 python-pip python3-pip python-dev python3-dev
    pip install django tornado markdown python-memcached web.py mongo uwsgi virtualenv virtualenvwrapper flask gevent jinja2 requests

    npm install forever coffee-script gulp mocha -g
