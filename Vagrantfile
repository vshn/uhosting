# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

Vagrant.configure(2) do |config|
  config.vm.box = "puppetlabs/ubuntu-14.04-64-puppet"

  config.vm.define "kawakawa" do |default|

    ## General VM settings
    default.vm.hostname = "kawakawa.vagrant.dev"

    ## Network settings
    default.vm.network "private_network", ip: '172.28.128.6'

    ## Synced folders
    default.vm.synced_folder ".", "/etc/puppet/modules/uhosting"
    default.vm.synced_folder ".", "/vagrant"

    ## Provisioning
    $inline_provisioning = <<SCRIPT
if [ ! -f /etc/.shell_already_provisioned ]; then
  echo "[INFO] Change sources.list to use ch mirror..."
  sed -i 's/us.archive/ch.archive/g' /etc/apt/sources.list
  echo "[INFO] Initial apt-get update..."
  apt-get update >/dev/null
  echo "[INFO] Configuration Puppet..."
  sed -i '/templatedir/d' /etc/puppet/puppet.conf
  touch /etc/.shell_already_provisioned
else
  echo "[INFO] shell provisioning already done..."
fi
SCRIPT
    default.vm.provision :shell, inline: $inline_provisioning

    default.librarian_puppet.puppetfile_dir = 'vagrant'
    default.librarian_puppet.placeholder_filename = '.gitkeep'
    default.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "vagrant"
      puppet.manifest_file     = "default.pp"
      puppet.hiera_config_path = "vagrant/hiera.yaml"
      puppet.facter            = { 'vagrant' => true }
      puppet.options           = "--verbose --modulepath /etc/puppet/modules:/vagrant/vagrant/modules"
    end
    # FACTER_vagrant='true' puppet apply --verbose --modulepath /etc/puppet/modules:/vagrant/vagrant/modules --hiera_config=/vagrant/vagrant/hiera.yaml --manifestdir /vagrant/vagrant /vagrant/vagrant/default.pp

    ## VirtualBox customization
    default.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end

  end

  ## Read hiera YAML and put all server_names into landrush
  config.landrush.enabled = true
  hieradata = YAML.load_file('vagrant/hieradata.yaml')
  hieradata['uhosting::sites'].each do |sitename,sitedata|
    sitedata['server_names'].each do |server_name|
      config.landrush.host server_name, '172.28.128.6'
      config.landrush.host "#{server_name}.vagrant.dev", '172.28.128.6'
    end
  end

end
