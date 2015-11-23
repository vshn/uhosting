# == Class: uhosting::profiles::uwsgi
#
# Installs and manages uWSGI application server in emperor mode
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
class uhosting::profiles::uwsgi {

  # We run in Emperor mode!
  package { [
    'uwsgi-core',
    'uwsgi-emperor',
    'uwsgi-infrastructure-plugins' ]:
      ensure => installed,
  } ->
  file { '/etc/uwsgi-emperor/emperor.ini':
    source => 'puppet:///modules/uhosting/emperor.ini',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  } ->
  file { '/etc/uwsgi-emperor/vassals':
    ensure  => directory,
    purge   => true,
    recurse => true,
  } ~>
  service { 'uwsgi-emperor':
    ensure => running,
    enable => true,
  }

  # create directory for the uwsgi sockets
  file { '/var/lib/uhosting':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0775',
  }

  # a world accessible spooler dir
  file { '/var/spool/uwsgi':
    ensure => directory,
    mode   => '0777',
  }

}
