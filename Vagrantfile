# -*- mode: ruby -*-
# vi: set ft=ruby :

$china_source = <<BASH
cat <<LIST > /etc/apt/sources.list
deb http://mirrors.ustc.edu.cn/ubuntu/ trusty main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ trusty-security main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ trusty-updates main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ trusty-proposed main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ trusty main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ trusty-security main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ trusty-updates main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ trusty-proposed main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ trusty-backports main restricted universe multiverse
LIST
BASH

$script = <<BASH
apt-get update
apt-get install -y python g++ make npm git nginx redis-server supervisor mongodb
update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10
npm --no-color install -g coffee-script bower nodemon mocha

cat <<'NGINX' > /etc/nginx/sites-enabled/rpadmin
server {
    listen 80;
    server_name rp.rpvhost.net;

    location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://unix:/tmp/rootpanel.sock:/;
    }
}
NGINX

usermod -G vagrant -a www-data
service nginx restart

BASH

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "rp.rpvhost.net"
# config.vm.provision "shell", inline: $china_source
  config.vm.provision "shell", inline: $script
  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end
end
