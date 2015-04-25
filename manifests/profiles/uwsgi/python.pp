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
    dev        => false,
    virtualenv => false,
    gunicorn   => false,
  } ->
  python::pip { 'uwsgitop': ensure => present }

}
