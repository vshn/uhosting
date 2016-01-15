# == Define: uhosting::resources::nodejs_package
#
# Installs a node package to a user's home directory.
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
define uhosting::resources::nodejs_package (
  $user,
  $homedir,
  $ensure = present,
) {
  include uhosting::profiles::nodejs

  $_package = regsubst($title, "^${user}-", "")
  $_package_split = split($_package, '@')
  $_package_name = $_package_split[0]
  $_package_version = $_package_split[1]
  $validate = "/${_package_name}:${_package_name}@${_package_version}"

  if $ensure == present {
    exec { "npm_install_${user}_${_package_name}":
      command     => "npm install ${_package}",
      cwd         => "${homedir}",
      environment => "HOME=${homedir}",
      path        => $::path,
      unless      => "npm list -p -l | grep -q '${validate}'",
      user        => $user,
      require     => File[ "/usr/local/bin/npm" ],
    }
  } else {
    exec { "npm_remove_${user}_${_package_name}":
      command     => "npm remove ${_package_name}",
      cwd         => "${homedir}",
      environment => "HOME=${homedir}",
      onlyif      => "npm list -p -l | grep -q '${validate}'",
      path        => $::path,
      user        => $user,
      require     => File[ "/usr/local/bin/npm" ],
    }
  }
}

