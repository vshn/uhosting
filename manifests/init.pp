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
  $redirects = undef,
  $dns_zones = undef,
) {

  validate_hash($sites)

  if $dns_zones {
    validate_hash($dns_zones)
    include uhosting::profiles::knot
  }

  # create site resources
  $site_names = keys($sites)
  resources::site { $site_names:
    data => $sites,
  }

}
