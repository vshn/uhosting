# == Define: uhosting::resources::nodejs_worker
#
# Creates a nodejs instance, managed by supervisord.
#
# === Parameters
#
# === Authors
#
# David Gubler <david.gubler@vshn.ch>
#
# === Copyright
#
# Copyright 2015 David Gubler, VSHN AG
#
define uhosting::resources::nodejs_worker (
  $ensure = present,
  $version = undef,
  $app,
) {
  validate_absolute_path($app)
  
  $_version = $version ? {
    undef    => $::nodejs_stable_version,
    'stable' => $::nodejs_stable_version,
    'latest' => $::nodejs_latest_version,
    default  => $version
  }
  
  if $version == "stable" {
    $_command = "/usr/local/bin/node"
  } else {
    $_command = "/usr/local/bin/node-${_version}"
  }

  ensure_resource('nodejs::install', "nodejs-${_version}", { 
    'make_install' => false, 
    'version' => $_version
  })
  supervisord::program { "nodejs-${name}":
    require                 => Nodejs::Install["nodejs-${_version}"],
    ensure                  => $ensure,
    command                 => "${_command} ${app}",
    user                    => $name,
    autorestart             => true,
    autostart               => true,
    redirect_stderr         => true,
    stderr_logfile          => "${name}-error.log",
    stderr_logfile_backups  => '7',
    stderr_logfile_maxbytes => '10MB',
    stdout_logfile          => "${name}.log",
    stdout_logfile_backups  => '7',
    stdout_logfile_maxbytes => '10MB',
  }
}

