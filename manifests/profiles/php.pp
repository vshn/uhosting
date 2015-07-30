#
class uhosting::profiles::php {

  if defined(Class['uhosting::profiles::uwsgi']) {
    package {
      'uwsgi-plugin-php':
        ensure  => installed,
        require => Package['uwsgi-core'];
    }
  }

  class { '::php':
    manage_repos => false,
    fpm          => true,
    dev          => true,
    composer     => true,
    pear         => true,
    phpunit      => false,
    extensions   => {
      'imagick'  => { 'provider' => 'apt' },
      'gmp'      => { 'provider' => 'apt' },
      'mcrypt'   => { 'provider' => 'apt' },
      'json'     => { 'provider' => 'apt' },
      'mysqlnd'  => { 'provider' => 'apt' },
    }
  }

}
