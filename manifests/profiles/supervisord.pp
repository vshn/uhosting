#
class uhosting::profiles::supervisord {

  # Install SupervisorD
  class { '::supervisord':
    package_provider => 'apt',
    service_name     => 'supervisor',
    executable       => '/usr/bin/supervisord',
    executable_ctl   => '/usr/bin/supervisorctl',
    install_init     => false,
    config_include   => '/etc/supervisor/conf.d',
    config_file      => '/etc/supervisor/supervisor.conf',
  }

}
