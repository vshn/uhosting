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
