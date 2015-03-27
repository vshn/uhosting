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
  $sites,
  $dns_zones = undef,
) inherits ::uhosting::params {

  validate_hash($sites)

}
