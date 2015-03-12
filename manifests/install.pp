# == Class uhosting::install
#
# This class is called from uhosting for install.
#
class uhosting::install inherits uhosting {

  package { $package_name:
    ensure => $package_ensure,
  }
}
