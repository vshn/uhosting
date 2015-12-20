# == Define: uhosting::app::wordpress
#
# Configures a vhost and app server for Wordpress.
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
# None
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::app::wordpress (
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

  $_webroot = $webroot

  #############################################################################
  ### Application server settings
  #############################################################################

  include uhosting::profiles::php
  include uhosting::profiles::supervisord
  $fpm_socket = "/var/lib/uhosting/php5-fpm-${name}.sock"

  # PHP-FPM pool
  $_php_values = {
    'post_max_size' => '100M',
    'upload_max_filesize' => '100M',
    'memory_limit' => '64M',
  }
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
    #php_admin_values         => $_php_admin_values,
    #php_admin_flags          => $_php_admin_flags,
    #php_flags                => $_php_flags,
    php_values               => $_php_values,
    #env_variables            => $_env_vars,
    require                  => Class['uhosting::profiles::php'],
  }

  #############################################################################
  ### App specific location and vhost settings
  #############################################################################

  include uhosting::profiles::nginx

  ## Create vhost

  $_app_vhost_params = {
    use_default_location => false,
    www_root             => $_webroot,
    index_files          => [ 'index.php' ],
    try_files            => [ '$uri', '$uri/', '=404' ],
    client_max_body_size => '100m',
  }
  $vhost_params = merge($vhost_defaults,$_app_vhost_params)
  $vhost_resource = { "${name}-wordpress" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)

  ## Configure special locations

  ::nginx::resource::location { "${name}-wordpress":
    vhost     => "${name}-wordpress",
    ssl       => $ssl,
    ssl_only  => $ssl,
    location  => '/',
    www_root  => $_webroot,
    try_files => ['$uri','$uri/','/index.php?q=$uri&$args'],
  }
  ::nginx::resource::location { "${name}-php":
    vhost              => "${name}-wordpress",
    ssl                => $ssl,
    ssl_only           => $ssl,
    location           => '~ \.php(?:$|/)',
    fastcgi            => "unix:${fpm_socket}",
    fastcgi_split_path => '^(.+?\.php)(/.*)$',
    rewrite_rules      => ['/wp-admin$ $scheme://$host$uri/ permanent'],
  }
  ::nginx::resource::location { "${name}-denydotfiles":
    vhost         => "${name}-wordpress",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '~ /\.',
    location_deny => ['all'],
    www_root      => $_webroot,
  }
  ::nginx::resource::location { "${name}-denyuploadphp":
    vhost         => "${name}-wordpress",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '~* /(?:uploads|files)/.*\.php$',
    location_deny => ['all'],
    www_root      => $_webroot,
  }
  ::nginx::resource::location { "${name}-staticexpire":
    vhost               => "${name}-wordpress",
    ssl                 => $ssl,
    ssl_only            => $ssl,
    location            => '~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$',
    location_custom_cfg => { 'expires' => 'max' },
  }

  #############################################################################
  ### Manage application code
  #############################################################################

  ## Pre-requisits

  #ensure_packages([ 'php5-curl',
  #                  'php5-apcu',
  #                  'php5-gd'])


}
