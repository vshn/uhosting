# == Class uhosting::service
#
# This class is meant to be called from uhosting.
# It ensure the service is running.
#
class uhosting::service inherits uhosting {

  if $service_manage {
    service { $service_name:
      ensure     => $service_ensure,
      enable     => $service_enable,
      hasstatus  => true,
      hasrestart => true,
    }
  }
}
