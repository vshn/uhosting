# == Class: uhosting::profiles::knot
#
# Installs and manages Knot DNS server
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
class uhosting::profiles::knot {

  class { '::knot':
    system        => { 'version' => 'off' },
    zones         => hiera('uhosting::dns_zones'),
    zone_defaults => hiera('uhosting::dns_zone_defaults',{}),
    keys          => hiera('uhosting::dns_zone_keys',{}),
    remotes       => hiera('uhosting::dns_zone_remotes',{}),
  }

}
