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
    apt-get install ntp quota quotatool

    mongo

        use admin
        db.addUser({user: 'rpadmin', pwd: 'password', roles: ['readWriteAnyDatabase', 'userAdminAnyDatabase', 'dbAdminAnyDatabase']})

    vi /etc/mongodb.conf

        auth = true

    rm /etc/php5/fpm/pool.d/www.conf
    rm /etc/nginx/sites-enabled/default
    
    vi /etc/nginx/fastcgi_params
    
        fastcgi_param   SCRIPT_FILENAME         $document_root$fastcgi_script_name;
    
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

    vi config.coffee

    make start

### Runtime

    apt-get install golang  

    apt-get install python python3 python-pip python3-pip python-dev python3-dev
    pip install django tornado markdown python-memcached web.py mongo uwsgi virtualenv virtualenvwrapper flask gevent jinja2 requests
