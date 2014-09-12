# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "rp.rpvhost.net"

  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.network "public_network", bridge: 'en0: Wi-Fi (AirPort)'

  config.vm.synced_folder ".", "/vagrant",
    owner: "rpadmin", group: "rpadmin"
end
