#
class uhosting::profiles::uwsgi {

  # We run in Emperor mode!
  #Exec['apt_update'] -> Package <| |>
  #apt::source { 'osso_ppa':
  #  comment  => 'uwsgi osso PPA',
  #  location => 'http://ppa.launchpad.net/osso/uwsgi/ubuntu',
  #  release  => $::lsbdistcodename,
  #  repos    => 'main',
  #  key      => {
  #    'id' => 'A8E0D05D50EC0EDA4958B44535CF57C9BD6901E2',
  #    'server' => 'hkp://keyserver.ubuntu.com:80',
  #  },
  #  include  => {
  #    'src' => false,
  #    'deb' => true,
  #  }
  #} ->
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
  #file { '/run/uwsgi':
  #  ensure => directory,
  #  owner  => 'www-data',
  #  group  => 'www-data',
  #  mode   => '0775',
  #}

  # a world accessible spooler dir
  file { '/var/spool/uwsgi':
    ensure => directory,
    mode   => '0777',
  }

}
