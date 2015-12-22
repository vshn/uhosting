# == Define: uhosting::resources::phpfpm_pool
#
# Creates PHP FPM pools. One master per site user, managed by SupervisorD.
#
# === Parameters
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::resources::phpfpm_pool (
  $ensure,
  $fpm_pm,
  $fpm_socket,
  $fpm_listen_backlog,
  $fpm_max_children = undef,
  $fpm_start_servers = undef,
  $fpm_min_spare_servers = undef,
  $fpm_max_spare_servers = undef,
  $fpm_max_requests = undef,
  $fpm_process_idle_timeout = undef,
  $php_admin_values = undef,
  $php_admin_flags = undef,
  $php_flags = undef,
  $php_values = undef,
  $php_version = '5.5',
  $env_variables = undef,
) {

  # validate data types
  if $php_admin_values { validate_hash($php_admin_values) }
  if $php_admin_flags { validate_hash($php_admin_flags) }
  if $php_flags { validate_hash($php_flags) }
  if $php_values { validate_hash($php_values) }
  if $env_variables { validate_hash($env_variables) }

  case $php_version {
    '5.4': {
      $_fpm_binary = '/usr/sbin/php5-fpm'
      $_master_config_file = "/etc/php5/fpm/${name}.conf"
    }
    '5.5': {
      $_fpm_binary = '/usr/sbin/php5-fpm'
      $_master_config_file = "/etc/php5/fpm/${name}.conf"
    }
    '5.6': {
      $_fpm_binary = '/usr/sbin/php5-fpm'
      $_master_config_file = "/etc/php5/fpm/${name}.conf"
    }
    '7.0': {
      $_fpm_binary = '/usr/sbin/php-fpm7.0'
      $_master_config_file = "/etc/php/7.0/fpm/${name}.conf"
    }
  }

  $ensure_process = $ensure ? {
    'present' => 'running',
    'absent'  => 'removed',
    default   => undef,
  }

  # write the pool specific configuration file
  # pm selection is done in the template
  file { $_master_config_file:
    ensure  => $ensure,
    content => template('uhosting/phpfpm_pool.conf.erb'),
    mode    => '0600',
    notify  => Supervisord::Supervisorctl["restart_php-fpm-${name}"],
  }

  # add the new php fpm master / pool to supervisor
  ::supervisord::program { "php-fpm-${name}":
    ensure                  => $ensure,
    ensure_process          => $ensure_process,
    command                 => "${_fpm_binary} --fpm-config ${_master_config_file}",
    user                    => 'root',
    autorestart             => true,
    autostart               => true,
    redirect_stderr         => true,
    stderr_logfile          => "${name}-error.log",
    stderr_logfile_backups  => '7',
    stderr_logfile_maxbytes => '10MB',
    stdout_logfile          => "${name}.log",
    stdout_logfile_backups  => '7',
    stdout_logfile_maxbytes => '10MB',
    stopsignal              => 'QUIT',
    subscribe               => File[$_master_config_file],
    require                 => Class['::php::fpm'],
  }
  ::supervisord::supervisorctl { "restart_php-fpm-${name}":
    command     => 'restart',
    process     => "php-fpm-${name}",
    refreshonly => true,
  }

}

