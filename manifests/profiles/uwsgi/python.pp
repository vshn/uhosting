# == Class: uhosting::profiles::uwsgi::python
#
# Installs and manages Python together with uWSGI
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
class uhosting::profiles::uwsgi::python {

  package {
    'uwsgi-plugin-python':
      ensure  => installed,
      require => Package['uwsgi-core'];
    'uwsgi-plugin-python3':
      ensure  => installed,
      require => Package['uwsgi-core'];
  }

  class { '::python':
    version    => 'system',
    pip        => true,
    dev        => true,
    virtualenv => true,
    gunicorn   => false,
  } ->
  python::pip { 'uwsgitop': ensure => present }

}
