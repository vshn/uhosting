# == Define: uhosting::app::owncloud
#
# Configures a vhost and app server for ownCloud.
##
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
# [*vhost_defaults*]
# [*webroot*]
# [*vassals_dir*]
#
# === app_settings
#
# [*max_upload_size*]
#   Default: 1024m
#   For example set this to 2G to allow 2GB uploads via the web frontend.
#   affects php post_max_size, upload_max_filesize and nginx client_max_body_size
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
# Bastian Widmer <bastian@amazee.io>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::app::owncloud (
  $app_settings,
  $ssl,
  $vhost_defaults,
  $webroot,
  $vassals_dir,
) {

  #############################################################################
  ### Prepare variables
  #############################################################################
  validate_hash($app_settings)
  validate_bool($ssl)
  validate_hash($vhost_defaults)
  validate_absolute_path($webroot)
  validate_string($webroot)

  if $app_settings['max_upload_size'] {
    $_max_upload_size = $app_settings['max_upload_size']
  } else {
    $_max_upload_size = '1024m'
  }

  #############################################################################
  ### Application server settings
  #############################################################################

  include uhosting::profiles::php
  include uhosting::profiles::supervisord
  $fpm_socket = "/var/lib/uhosting/php5-fpm-${name}.sock"

  # PHP-FPM pool
  $_php_values = {
    'post_max_size'       => $_max_upload_size,
    'upload_max_filesize' => $_max_upload_size,
    'memory_limit'        => '128M',
  }

  if $env_vars {
    validate_hash($env_vars)
    $env_vars = $env_vars
  }

  $default_env_vars = {
    'db_host'     => 'localhost',
    'db_name'     => $name,
    'db_password' => $db_password,
    'db_user'     => $name,
    'PATH'        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    'sitename'    => $name,
  }
  $_env_vars = merge($default_env_vars,$env_vars)

  $fpm_pm = 'ondemand'
  $fpm_listen_backlog = '65535'
  $fpm_max_children = 10
  $fpm_max_requests = 500
  $fpm_process_idle_timeout = '10s'

  ::uhosting::resources::phpfpm_pool { $name:
    ensure                   => $ensure,
    fpm_pm                   => $fpm_pm,
    fpm_socket               => $fpm_socket,
    fpm_listen_backlog       => $fpm_listen_backlog,
    fpm_max_children         => $fpm_max_children,
    fpm_start_servers        => $fpm_start_servers,
    fpm_min_spare_servers    => $fpm_min_spare_servers,
    fpm_max_spare_servers    => $fpm_max_spare_servers,
    fpm_max_requests         => $fpm_max_requests,
    fpm_process_idle_timeout => $fpm_process_idle_timeout,
    php_admin_values         => $_php_admin_values,
    php_admin_flags          => $_php_admin_flags,
    php_flags                => $_php_flags,
    php_values               => $_php_values,
    php_version              => $::uhosting::profiles::php::php_version,
    env_variables            => $default_env_vars,
    require                  => Class['::php'],
  }

  #############################################################################
  ### App specific location and vhost settings
  #############################################################################

  include uhosting::profiles::nginx

  ## Create vhost
  $_app_vhost_params = {
    use_default_location => false,
    www_root => $webroot,
    # index_files => [ 'index.php' ],
    # client_max_body_size => $_max_upload_size,
    rewrite_rules => [
      '^/caldav(.*)$ /remote.php/caldav$1 redirect',
      '^/carddav(.*)$ /remote.php/carddav$1 redirect',
      '^/webdav(.*)$ /remote.php/webdav$1 redirect',
    ],
    raw_append => [
      'gzip on;',
      'gzip_comp_level 9;',
      'gzip_http_version 1.1;',
      'gzip_proxied any;',
      'gzip_min_length 10;',
      'gzip_buffers 16 8k;',
      'gzip_types text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript application/xhtml+xml;',
      'gzip_disable "MSIE [1-6].(?!.*SV1)";',
      'gzip_vary on;'
    ]    ,
  }
  $vhost_params = merge($vhost_defaults,$_app_vhost_params)
  $vhost_resource = { "${name}-owncloud" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)

  ::nginx::resource::location { "${name}-root":
    vhost         => "${name}-owncloud",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '/',
    www_root      => $webroot,
    rewrite_rules => [
      '^/.well-known/host-meta /public.php?service=host-meta last',
      '^/.well-known/host-meta.json /public.php?service=host-meta-json last',
      '^/.well-known/carddav /remote.php/carddav/ redirect',
      '^/.well-known/caldav /remote.php/caldav/ redirect',
      '^(/core/doc/[^\/]+/)$ $1/index.html',
      '^/caldav(.*)$ /remote.php/caldav$1 redirect',
      '^/carddav(.*)$ /remote.php/carddav$1 redirect',
      '^/webdav(.*)$ /remote.php/webdav$1 redirect',
    ],
    try_files     => ['$uri','$uri/','/index.php'],
  }

  ::nginx::resource::location { "${name}-php":
    vhost               => "${name}-owncloud",
    ssl                 => $ssl,
    ssl_only            => $ssl,
    location            => '~ \.php(?:$|/)',
    fastcgi             => "unix:${fpm_socket}",
    location_cfg_append => {
      'client_max_body_size' => $_max_upload_size,
      'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
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
  ensure_packages([ 'php-curl',
                    'php-intl',
                    'php-xmlrpc',
                    'php-apcu',
                    'php-gd',
                    'php-zip'])

  ## Checkout Owncloud Application to webroot
  vcsrepo { $webroot:
    ensure     => present,
    provider   => git,
    source     => 'https://github.com/owncloud/core.git',
    revision   => $app_settings['version'],
    submodules => true,
    user       => $name,
    require    => File[$webroot],
    notify     => [Exec['oc_set_owner'], Exec['oc_set_mode']],
  }->
  #Create Data Dir
  file { "${webroot}/data/":
    ensure => directory,
    mode   => '0644',
    owner  => $name,
  }
  ->
  exec { 'oc_set_owner':
  path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  command     => "chown -R ${name}:www-data $webroot/data $webroot/config $webroot/apps $webroot/themes;",
  refreshonly => true,
  }
  exec { 'oc_set_mode':
  path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  command     => "find $webroot/ -type f -print0 | xargs -0 chmod 0640; find $webroot/ -type d -print0 | xargs -0 chmod 0750",
  refreshonly => true,
  }
}
