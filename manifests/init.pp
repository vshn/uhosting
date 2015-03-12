# == Class: uhosting
#
# Full description of class uhosting here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
# === Examples
#
#  class { 'uhosting':
#    sample_parameter => 'sample value',
#  }
#
# === Authors
#
# tobru
#
# === Copyright
#
# Copyright 2015 tobru
#
class uhosting (
  $package_ensure      = $::uhosting::params::package_ensure,
  $package_name        = $::uhosting::params::package_name,
  $service_name        = $::uhosting::params::service_name,
  $service_enable      = $::uhosting::params::service_enable,
  $service_ensure      = $::uhosting::params::service_ensure,
  $service_manage      = $::uhosting::params::service_manage,
) inherits ::uhosting::params {

  # validate parameters here:
  # validate_absolute_path, validate_bool, validate_string, validate_hash
  # validate_array, ... (see stdlib docs)

  class { '::uhosting::install': } ->
  class { '::uhosting::config': } ~>
  class { '::uhosting::service': } ->
  Class['::uhosting']

  contain ::uhosting::install
  contain ::uhosting::config
  contain ::uhosting::service

}
