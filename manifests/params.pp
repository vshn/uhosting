# == Class uhosting::params
#
# This class is meant to be called from uhosting.
# It sets variables according to platform.
#
class uhosting::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'uhosting'
      $service_name = 'uhosting'
    }
    'RedHat', 'Amazon': {
      $package_name = 'uhosting'
      $service_name = 'uhosting'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }

  # package parameters
  $package_ensure = installed

  # service parameters
  $service_enable = true
  $service_ensure = running
  $service_manage = true

}
