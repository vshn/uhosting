# create a php fpm pool
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
  $env_variables = undef,
) {

  # validate data types
  if $php_admin_values { validate_hash($php_admin_values) }
  if $php_admin_flags { validate_hash($php_admin_flags) }
  if $php_flags { validate_hash($php_flags) }
  if $php_values { validate_hash($php_values) }
  if $env_variables { validate_hash($env_variables) }

  $master_config_file = "/etc/php5/fpm/${name}.conf"
  $ensure_process = $ensure ? {
    'present' => 'running',
    'absent'  => 'removed',
    default   => undef,
  }

  # write the pool specific configuration file
  # pm selection is done in the template
  file { $master_config_file:
    ensure  => $ensure,
    content => template('uhosting/phpfpm_pool.conf.erb'),
    mode    => '0600',
    notify  => Supervisord::Supervisorctl["restart_php5-fpm-${name}"],
  }

  # add the new php fpm master / pool to supervisor
  ::supervisord::program { "php5-fpm-${name}":
    ensure                  => $ensure,
    ensure_process          => $ensure_process,
    command                 => "/usr/sbin/php5-fpm --fpm-config ${master_config_file}",
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
    subscribe               => File[$master_config_file],
  }
  ::supervisord::supervisorctl { "restart_php5-fpm-${name}":
    command     => 'restart',
    process     => "php5-fpm-${name}",
    refreshonly => true,
  }

}

