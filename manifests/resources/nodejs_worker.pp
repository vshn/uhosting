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
  $app,
  $ensure = present,
  $version = undef,
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

  $_nodejs_install = {
    'make_install'  => false, 
    'version'       => $_version
  }
  ensure_resource('nodejs::install', "nodejs-${_version}", $_nodejs_install)

  supervisord::program { "nodejs-${name}":
    ensure                  => $ensure,
    autorestart             => true,
    autostart               => true,
    command                 => "${_command} ${app}",
    redirect_stderr         => true,
    stderr_logfile          => "${name}-error.log",
    stderr_logfile_backups  => '7',
    stderr_logfile_maxbytes => '10MB',
    stdout_logfile          => "${name}.log",
    stdout_logfile_backups  => '7',
    stdout_logfile_maxbytes => '10MB',
    user                    => $name,
    require                 => Nodejs::Install["nodejs-${_version}"],
  }
  sudo::conf { "supervisord-manage_nodejs-${name}":
    content   => [  "${name} ALL=(root) NOPASSWD: /usr/bin/supervisorctl stop nodejs-${name}",
                    "${name} ALL=(root) NOPASSWD: /usr/bin/supervisorctl start nodejs-${name}",
                    "${name} ALL=(root) NOPASSWD: /usr/bin/supervisorctl restart nodejs-${name}" ],
  }
}

