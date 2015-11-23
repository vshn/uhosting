# == Define: uhosting::app::owncloud
#
# Configures a vhost and app server for ownCloud.
#
# If `app_settings[manage_package]` is true, then ownCloud is installed
# system wide. This is good for a server which only has one ownCloud
# instance running. Else you better install ownCloud by hand into to
# webroot.
#
# === External Parameters
#
# This parameters are specific to the app profile
#
# [*app_settings*]
#   Default: {}
#   Hash to pass application specific settings here. Details see below.
#
# === Internal / Private Parameters
#
# This parameters are coming from the calling class and are described in
# more details there.
#
# [*app_settings*]
# [*ssl*]
# [*vassals_dir*]
# [*vhost_defaults*]
# [*webroot*]
#
# === app_settings
#
# [*manage_package*]
#   Default: false
#   Defines if the owncloud-server package should be installed from the official
#   ownCloud repository.
#
# [*package_version*]
#   Default: empty
#   If manage_package is true this can be used to chose which package version to install.
#   It also pins this application version in APT.
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::app::owncloud (
  $app_settings,
  $ssl,
  $vassals_dir,
  $vhost_defaults,
  $webroot,
) {

  #############################################################################
  ### Prepare variables
  #############################################################################

  validate_hash($app_settings)
  validate_bool($ssl)
  validate_hash($vhost_defaults)
  validate_absolute_path($webroot)

  if $app_settings['manage_package'] {
    $_webroot = '/var/www/owncloud/'
  } else {
    $_webroot = $webroot
  }

  #############################################################################
  ### Application server settings
  #############################################################################

  include uhosting::profiles::uwsgi
  include uhosting::profiles::php
  $plugins = 'php'
  $vassal_params = {
    'static-skip-ext' => '.php',
    'check-static'    => $_webroot,
    'chdir'           => $_webroot,
    'cron'            => "-3 -1 -1 -1 -1 /usr/bin/php -f ${_webroot}cron.php 1>/dev/null",
    'php-docroot'     => $_webroot,
    'php-allowed-ext' => '.php',
    'php-index'       => 'index.php',
    'php-set'         => [
      'date.timezone=Europe/Zurich',
      'post_max_size=1000M',
      'upload_max_filesize=1000M',
      'always_populate_raw_post_data=-1',
      'default_charset=utf-8',
      "error_log=/var/log/php/${name}.log",
    ],
  }
  file { "${vassals_dir}/${name}.ini":
    content => template('uhosting/uwsgi_vassal.ini.erb'),
    require => Class['uhosting::profiles::php'],
  }

  #############################################################################
  ### App specific location and vhost settings
  #############################################################################

  include uhosting::profiles::nginx

  ## Create vhost

  $_app_vhost_params = {
    use_default_location => false,
    www_root             => $_webroot,
    rewrite_rules        => [
      '^/caldav(.*)$ /remote.php/caldav$1 redirect',
      '^/carddav(.*)$ /remote.php/carddav$1 redirect',
      '^/webdav(.*)$ /remote.php/webdav$1 redirect',
    ],
  }
  $vhost_params = merge($vhost_defaults,$_app_vhost_params)
  $vhost_resource = { "${name}-owncloud" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)

  ## Configure special locations

  ::nginx::resource::location { "${name}-root":
    vhost         => "${name}-owncloud",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '/',
    www_root      => $_webroot,
    rewrite_rules => [
      '^/.well-known/host-meta /public.php?service=host-meta last',
      '^/.well-known/host-meta.json /public.php?service=host-meta-json last',
      '^/.well-known/carddav /remote.php/carddav/ redirect',
      '^/.well-known/caldav /remote.php/caldav/ redirect',
      '^(/core/doc/[^\/]+/)$ $1/index.html',
    ],
    try_files     => ['$uri','$uri/','/index.php'],
  }
  ::nginx::resource::location { "${name}-php":
    vhost               => "${name}-owncloud",
    ssl                 => $ssl,
    ssl_only            => $ssl,
    location            => '~ \.php(?:$|/)',
    uwsgi               => "unix:/var/lib/uhosting/${name}.socket",
    location_cfg_append => { 'uwsgi_modifier1' => '14' },
  }
  ::nginx::resource::location { "${name}-denies":
    vhost               => "${name}-owncloud",
    ssl                 => $ssl,
    ssl_only            => $ssl,
    location            => '~ ^/(?:\.htaccess|data|config|db_structure\.xml|README)',
    location_custom_cfg => { 'deny' => 'all' },
  }

  #############################################################################
  ### Manage application code
  #############################################################################

  ## Pre-requisits

  ensure_packages([ 'php5-curl',
                    'php5-intl',
                    'php5-xmlrpc',
                    'php5-xsl',
                    'php5-apcu',
                    'php5-gd'])

  ## If needed install application package

  if $app_settings['manage_package'] {
    if $app_settings['package_version'] {
      $_package_version = $app_settings['package_version']
      ::apt::pin { 'hold-owncloud-server':
        packages => 'owncloud-server',
        version  => $app_settings['package_version'],
        priority => 1001,
      }
    } else {
      $_package_version = undef
    }
    Exec['apt_update'] -> Package['owncloud-server']
    ::apt::source { 'owncloud':
      comment  => 'Official repository for ownCloud',
      location => "http://download.owncloud.org/download/repositories/stable/Ubuntu_${::lsbdistrelease}/",
      release  => ' ',
      repos    => '/',
      key      => {
        id     => 'BCECA90325B072AB1245F739AB7C32C35180350A',
        source => 'https://download.owncloud.org/download/repositories/stable/Ubuntu_14.04/Release.key',
      },
      include  => {
        src    => false,
        deb    => true,
      },
    } ->
    package { 'owncloud-server':
      ensure => $_package_version,
    } ->
    file { '/var/www/owncloud':
      ensure  => directory,
      owner   => $name,
      group   => $name,
      recurse => true,
    }

  }

}
