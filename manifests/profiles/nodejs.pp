# == Class: uhosting::profiles::nodejs
#
# Installs and manages NodeJS
#
# === Authors
#
# David Gubler <david.gubler@vshn.ch>
#
# === Copyright
#
# Copyright 2015 David Gubler, VSHN AG
#
class uhosting::profiles::nodejs {
  # Make sure we always have the stable version installed as a default. This also provides the default npm.
  # Note: All of these might be included multiple times. Only set things up once.

  $_nodejs_install = {
    'make_install' => false,
    'version' => $::nodejs_stable_version,
  }
  ensure_resource('nodejs::install', "nodejs-${::nodejs_stable_version}", $_nodejs_install)

  $_nodejs_global = {
    'ensure'  => "/usr/local/node/node-${::nodejs_stable_version}/bin/node",
    'require' => Nodejs::Install[ "nodejs-${::nodejs_stable_version}" ],
  }
  ensure_resource('file', '/usr/local/bin/node', $_nodejs_global)

  $_npm_global = {
    'ensure' => "/usr/local/node/node-${::nodejs_stable_version}/bin/npm",
    'require' => File[ '/usr/local/bin/node' ],
  }
  ensure_resource('file', '/usr/local/bin/npm', $_npm_global)
}
