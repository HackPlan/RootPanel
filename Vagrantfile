# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "rp.rpvhost.net"

  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.network "public_network"
end
