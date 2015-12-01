# == Define: uhosting::app::cachet
#
# Configures a vhost and app server for Cachet Status Page.
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
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::app::cachet (
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

  #############################################################################
  ### Application server settings
  #############################################################################

  include uhosting::profiles::uwsgi
  include uhosting::profiles::php
  $plugins = 'php'
  $vassal_params = {
    'static-skip-ext' => '.php',
    'check-static'    => $webroot,
    'chdir'           => $webroot,
    'cron2'           => "minute=-10,unique=1 /usr/bin/php5 ${webroot}/artisan schedule:run 1>/dev/null",
    'php-docroot'     => '',
    'php-allowed-ext' => '.php',
    'php-index'       => 'index.php',
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
    www_root             => $webroot,
  }
  $vhost_params = merge($vhost_defaults,$_app_vhost_params)
  $vhost_resource = { "${name}-cachet" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)

  ## Configure special locations

  ::nginx::resource::location { "${name}-root":
    vhost         => "${name}-cachet",
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '/',
    www_root      => $webroot,
    try_files     => ['$uri','/index.php$is_args$args'],
  }
  ::nginx::resource::location { "${name}-php":
    vhost               => "${name}-cachet",
    ssl                 => $ssl,
    ssl_only            => $ssl,
    location            => '~ \.php(?:$|/)',
    uwsgi               => "unix:/var/lib/uhosting/${name}.socket",
    location_cfg_append => { 'uwsgi_modifier1' => '14' },
  }

  #############################################################################
  ### Manage application code
  #############################################################################

  ## Pre-requisits

  #ensure_packages([ 'php5-curl',
  #                  'php5-gd'])

}
