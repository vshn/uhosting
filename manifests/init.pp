# == Class: uhosting
#
# This is the main class of uhosting.
# It is used to generate sites and includes the needed classes.
#
# === Parameters
#
# [*sites*]
#   Hash of sites. See README for details.
#
# [*redirects*]
#   Hash of redirects. See README for details.
#
# [*dns_zones*]
#   Hash of DNS zones. See README for details.
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
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
  ::uhosting::resources::site { $site_names:
    data => $sites,
  }

}
