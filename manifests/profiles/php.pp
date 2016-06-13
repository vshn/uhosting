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

  $_version_repo = 'ondrej/php'
  $package_prefix = "php${php_version}-"
  $cfg_root = "/etc/php/${php_version}"
  $config_root_ini = "/etc/php/${php_version}"
  $fpm_service_name = "php${php_version}-fpm"

  if $php_version == '7.0' {
    $ext_tool_enable = '/usr/sbin/phpenmod'
    $ext_tool_query = '/usr/sbin/phpquery'
  } else {
    $ext_tool_enable = undef
    $ext_tool_query = undef
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
