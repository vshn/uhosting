#
class uhosting::profiles::knot {

  class { '::knot':
    system => { 'version' => 'off' },
    zones  => hiera('uhosting::dns_zones'),
  }

}
