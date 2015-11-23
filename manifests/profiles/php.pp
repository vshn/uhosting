# == Class: uhosting::profiles::php
#
# Installs and manages PHP, including uWSGI plugin installation
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
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
