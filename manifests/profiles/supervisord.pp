# == Class: uhosting::profiles::supervisord
#
# Installs and manages Supervisord
# Mainly used for PHP FPM pools
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
class uhosting::profiles::supervisord {

  # supervisor package installation needs python-pip
  ensure_packages('python-pip')

  # Install SupervisorD
  class { '::supervisord':
    package_provider      => 'apt',
    service_name          => 'supervisor',
    executable            => '/usr/bin/supervisord',
    executable_ctl        => '/usr/bin/supervisorctl',
    install_init          => false,
    config_include        => '/etc/supervisor/conf.d',
    config_include_purge  => true,
    config_file           => '/etc/supervisor/supervisord.conf',
    require               => Package['python-pip']
  }
}
