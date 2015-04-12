#
class uhosting::profiles::uwsgi {

  # We run in Emperor mode!
  package { [
    'uwsgi-core',
    'uwsgi-emperor',
    'uwsgi-infrastructure-plugins',
    'uwsgi-app-integration-plugins' ]:
      ensure => installed,
  } ->
  file { '/etc/uwsgi-emperor/emperor.ini':
    source => 'puppet:///modules/uhosting/emperor.ini',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  } ~>
  service { 'uwsgi-emperor':
    ensure => running,
    enable => true,
  }

  # create directory for the uwsgi sockets
  file { '/run/uwsgi':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0775',
  }

  # language stacks
  class { 'python':
    version    => 'system',
    pip        => true,
    dev        => false,
    virtualenv => false,
    gunicorn   => false,
  } ->
  python::pip { 'uwsgitop': ensure => present }

  class { 'ruby':
  } ->
  package { 'ruby-rack':
    ensure   => installed,
  }

}
