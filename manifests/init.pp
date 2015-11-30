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
# [*certificates*]
#   Hash of certificate data. See README for details.
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
  $certificates = undef,
) {

  ## Validate mandatory parameters

  validate_hash($sites)

  ## Manage DNS if there are DNS zone defined

  if $dns_zones {
    validate_hash($dns_zones)
    include uhosting::profiles::knot
  }

  ## Create SSL certificate and key files if there are any defined

  if $certificates {
    validate_hash($certificates)
    $cert_names = keys($certificates)
    ensure_packages('ssl-cert')
    ::uhosting::resources::certificates { $cert_names:
      data    => $certificates,
      require => Package['ssl-cert'],
    }
  }

  ## Create Sites

  $site_names = keys($sites)
  ::uhosting::resources::site { $site_names:
    data => $sites,
  }

}
