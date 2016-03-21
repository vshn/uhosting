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
class uhosting::profiles::postgresql (
  $listen_addresses = '127.0.0.1'
  ) {

  validate_ip_address($listen_addresses)

  include ::postgresql::client
  class { '::postgresql::server':
    listen_addresses => $listen_addresses,
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
