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
class uhosting::profiles::php (
  $php_version = '5.5',
) {

  if defined(Class['uhosting::profiles::uwsgi']) {
    package {
      'uwsgi-plugin-php':
        ensure  => installed,
        require => Package['uwsgi-core'];
    }
  }

  $_version_repo = $php_version ? {
    '5.4' => 'ondrej/php5-oldstable',
    '5.5' => 'ondrej/php5',
    '5.6' => 'ondrej/php5-5.6',
    '7.0' => 'ondrej/php',
  }

  if $php_version == '7.0' {
    $config_root_ini = '/etc/php/7.0'
    $ext_tool_enable = '/usr/sbin/phpenmod'
    $ext_tool_query = '/usr/sbin/phpquery'
    $package_prefix = 'php7.0-'
    $fpm_service_name = 'php7.0-fpm'
    $cfg_root = '/etc/php/7.0'
  } else {
    $config_root_ini = undef
    $ext_tool_enable = undef
    $ext_tool_query = undef
    $package_prefix = undef
    $fpm_service_name = undef
    $cfg_root = undef
  }

  apt::source { 'sury_php_ppa':
    comment  => 'PHP PPA of Ondrej Sury',
    location => "http://ppa.launchpad.net/${_version_repo}/ubuntu",
    release  => $::lsbdistcodename,
    repos    => 'main',
    key      => {
      'id'     => '14AA40EC0831756756D7F66C4F4EA0AAE5267A6C',
      'server' => 'keyserver.ubuntu.com',
    },
    include  => {
      'src' => true,
      'deb' => true,
    },
  } ->
  class { '::php::params':
    cfg_root => $cfg_root,
  } ->
  class { '::php':
    manage_repos    => false,
    fpm             => true,
    dev             => true,
    composer        => true,
    pear            => true,
    phpunit         => false,
    config_root_ini => $config_root_ini,
    ext_tool_enable => $ext_tool_enable,
    ext_tool_query  => $ext_tool_query,
    package_prefix  => $package_prefix,
    extensions      => {
      #'imagick'     => { 'provider' => 'apt' },
      #'gmp'         => { 'provider' => 'apt' },
      #'mcrypt'      => { 'provider' => 'apt' },
      #'json'        => { 'provider' => 'apt' },
      #'mysqlnd'     => { 'provider' => 'apt' },
    },
    require         => Exec['apt_update'],
  }
  Service <| tag == 'php5-fpm' |> {
    name   => $fpm_service_name,
    enable => false,
    ensure => stopped,
  }

}
