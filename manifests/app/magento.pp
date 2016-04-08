# == Define: uhosting::app::magento
#
# Configures a vhost and app server for Magento.
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
# [*vhost_defaults*]
# [*webroot*]
#
# === app_settings
#
# None
#
# === Authors
#
# Marco Fretz <marco.fretz@vshn.ch>
#
# === Copyright
#
# Copyright 2016 Marco Fretz, VSHN AG
#
define uhosting::app::magento (
  $app_settings,
  $ssl,
  $vhost_defaults,
  $vassals_dir,
  $webroot,
) {

  #############################################################################
  ### Prepare variables
  #############################################################################

  validate_hash($app_settings)
  validate_bool($ssl)
  validate_hash($vhost_defaults)
  validate_absolute_path($webroot)

  if $app_settings['max_upload_size'] {
    $_max_upload_size = $app_settings['max_upload_size']
  } else {
    $_max_upload_size = '100m'
  }

  #############################################################################
  ### Application server settings
  #############################################################################

  include uhosting::profiles::php
  include uhosting::profiles::supervisord
  $fpm_socket = "/var/lib/uhosting/php5-fpm-${name}.sock"

  # PHP-FPM pool
  $_php_values = {
    'post_max_size' => $_max_upload_size,
    'upload_max_filesize' => $_max_upload_size,
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
    php_values               => $_php_values,
    php_version              => $::uhosting::profiles::php::php_version,
    require                  => Class['uhosting::profiles::php'],
  }

  #############################################################################
  ### App specific location and vhost settings
  #############################################################################

  include uhosting::profiles::nginx

  ## Create vhost
  $_app_vhost_params = {
    use_default_location => false,
    www_root => $webroot,
    index_files => [ 'index.php' ],
    try_files => [ '$uri', '$uri/', '@handler' ],
    client_max_body_size => $_max_upload_size,
  }
  $vhost_params = merge($vhost_defaults,$_app_vhost_params)
  $vhost_resource = { "${name}-magento" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)

  ## Configure special locations

  # deny locations
  ::nginx::resource::location { "${name}-app_files":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '^~ /app/',
    location_deny => [ 'all' ],
    www_root      => $webroot,
  }
  ::nginx::resource::location { "${name}-includes_files":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '^~ /includes/',
    location_deny => [ 'all' ],
    www_root      => $webroot,
  }
  ::nginx::resource::location { "${name}-lib_files":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '^~ /lib/',
    location_deny => [ 'all' ],
    www_root      => $webroot,
  }
  ::nginx::resource::location { "${name}-pkginfo_files":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '^~ /pkginfo/',
    location_deny => [ 'all' ],
    www_root      => $webroot,
  }
  ::nginx::resource::location { "${name}-config_file":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '^~ /report/config.xml',
    location_deny => [ 'all' ],
    www_root      => $webroot,
  }
  ::nginx::resource::location { "${name}-dotfiles":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '/.',
    raw_prepend   => 'return 403;',
    www_root      => $webroot,
  }
  ::nginx::resource::location { "${name}-var_folder":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '^~ /var/',
    location_deny => [ 'all' ],
    www_root      => $webroot,
  }

  #php handler locations
  ::nginx::resource::location { "${name}-root":
    vhost     => "${name}-magento",
    ssl       => $ssl,
    ssl_only  => $ssl,
    priority  => 450,
    location  => '/',
    www_root  => $webroot,
    try_files => ['$uri','$uri/','@fronthandler'],
  }
  ::nginx::resource::location { "${name}-fronthandler":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    priority      => 539,
    location      => '@fronthandler',
    www_root      => $webroot,
    rewrite_rules =>  [ '/ /index.php' ],
  }

  ::nginx::resource::location { "${name}-php_rewirte":
    vhost         => "${name}-magento",
    ssl           => $ssl,
    ssl_only      => $ssl,
    priority      => 540,
    location      => '~ .php/',
    rewrite_rules => [ '^(.*.php)/ $1 last' ],
    www_root      => $webroot,
  }

  ::nginx::resource::location { "${name}-php_handler":
    vhost              => "${name}-magento",
    ssl                => $ssl,
    ssl_only           => $ssl,
    location           => '~ .php$',
    priority           => 550,
    fastcgi            => "unix:${fpm_socket}",
    fastcgi_param      => { 'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name' },
    raw_prepend        => [ 'expires off;', 'if (!-e $request_filename) { rewrite / /index.php last; }' ]
  }


  #############################################################################
  ### Manage application code
  #############################################################################

  ## Pre-requisits

  ensure_packages([ 'php5-mysql',
                    'php-crypt-gpg',
                    'php5-curl',
                    'php5-mcrypt',
                    'php5-apcu',
                    'php5-gd'])


}
