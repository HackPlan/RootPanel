# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # based on ubuntu/trusty64
  config.vm.box = "jysperm/rootpanel"
  config.vm.hostname = "rp.rpvhost.net"

  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.synced_folder ".", "/vagrant",
    owner: "rpadmin", group: "rpadmin"
end
