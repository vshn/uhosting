#
class uhosting::profiles::uwsgi::ruby {

  package {
    'uwsgi-plugin-rack-ruby1.9.1':
      ensure  => installed,
      require => Package['uwsgi-core'];
    'ruby-rack':
      ensure  => installed;
  }

  class { '::ruby': }

}
