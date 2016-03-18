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
  $postgresql_password,
  ){

  validate_string($postgresql_password)

  include ::postgresql::client
  class { '::postgresql::server':
    #ip_mask_deny_postgres_user => '0.0.0.0/32',
    #ip_mask_allow_all_users    => '0.0.0.0/0',
    #listen_addresses           => '*',
    #ipv4acls                   => ['hostssl all johndoe 192.168.0.0/24 cert'],
    # postgres_password          => $postgresql_password,
    # package_name => 'postgresql-9.3',
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
