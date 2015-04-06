# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "puppetlabs/ubuntu-14.04-64-puppet"

  config.vm.define "default" do |default|
    default.librarian_puppet.puppetfile_dir = 'vagrant'
    default.librarian_puppet.placeholder_filename = '.gitkeep'

    default.vm.network "forwarded_port", guest: 80, host: 8080
    default.vm.network "forwarded_port", guest: 443, host: 1443

    default.vm.synced_folder ".", "/etc/puppet/modules/uhosting"
    default.vm.synced_folder ".", "/vagrant"

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
    default.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "vagrant"
      puppet.manifest_file     = "default.pp"
      puppet.hiera_config_path = "vagrant/hiera.yaml"
      puppet.options           = "--verbose --modulepath /etc/puppet/modules:/vagrant/vagrant/modules"
    end

    default.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end

  end

end
