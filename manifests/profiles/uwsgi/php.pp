#
class uhosting::profiles::uwsgi::php {

  package {
    'uwsgi-plugin-php':
      ensure  => installed,
      require => Package['uwsgi-core'];
    'php5-cli':
      ensure => installed;
  }

}
