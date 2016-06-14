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
# [*max_upload_size*]
#   Default: 1024m
#   For example set this to 2G to allow 2GB uploads via the web frontend.
#   affects php post_max_size, upload_max_filesize and nginx client_max_body_size
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
  $repo_url = 'https://download.owncloud.org/download/repositories/8.2/xUbuntu_',
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

  if $app_settings['max_upload_size'] {
    $_max_upload_size = $app_settings['max_upload_size']
  } else {
    $_max_upload_size = '1024m'
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
      "post_max_size=${_max_upload_size}",
      "upload_max_filesize=${_max_upload_size}",
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
    www_root => $_webroot,
    rewrite_rules => [
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
    location_cfg_append => {
      'uwsgi_modifier1' => '14',
      'client_max_body_size' => $_max_upload_size,
    },
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

  ensure_packages([ 'php5.5-curl',
                    'php5.5-intl',
                    'php5.5-xmlrpc',
                    'php5.5-xsl',
                    'php5.5-apcu',
                    'php5.5-gd'])

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
      location => "${repo_url}${::lsbdistrelease}/",
      release  => ' ',
      repos    => '/',
      key      => {
        id => 'BCECA90325B072AB1245F739AB7C32C35180350A',
        source => 'https://download.owncloud.org/download/repositories/stable/Ubuntu_14.04/Release.key',
      },
      include  => {
        src => false,
        deb => true,
      },
    } ->
    package { 'owncloud-server':
      ensure => $_package_version,
    } ~>
    # see https://doc.owncloud.org/server/8.0/admin_manual/installation/installation_wizard.html#strong-perms-label
    exec { 'oc_set_owner':
      path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      command     => "chown -R root:www-data $_webroot; chown -R ${name}:www-data $_webroot/data $_webroot/config $_webroot/apps $_webroot/themes;",
      refreshonly => true, # run only when package is installed or upgraded
    } ~>
    exec { 'oc_set_mode':
      path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
      command     => "find $_webroot/ -type f -print0 | xargs -0 chmod 0640; find $_webroot/ -type d -print0 | xargs -0 chmod 0750",
      refreshonly => true, # run only when package is installed or upgraded
    }
  }

}
