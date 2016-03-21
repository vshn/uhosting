# == Class: uhosting::profiles::postgresql
#
# Installs and manages PostgreSQL server
#
# === Parameters
#
# === Authors
#
# Marco Fretz <marco.fretz@vshn.ch>
#
# === Copyright
#
# Copyright 2016 Marco Fretz, VSHN AG
#
class uhosting::profiles::postgresql () {

  validate_string($postgresql_password)

  include ::postgresql::client
  class { '::postgresql::server':
  }

  ### Resources
  ## Get sites from hiera
  $sitehash = hiera('uhosting::sites')
  $sites = keys($sitehash)

  ## Create the databases
  ::uhosting::resources::postgresql { $sites:
    data => $sitehash,
  }
}
