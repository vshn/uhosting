# == Class: uhosting::resources::certificates
#
# Generates files with certificate and key content
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::resources::certificates (
  $data,
) {

  $_certificate = $data['certificate']
  $_key = $data['key']

  file { "/etc/ssl/certs/${name}.pem":
    ensure  => file,
    content => $_certificate,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
  file { "/etc/ssl/private/${name}.pem":
    ensure  => file,
    content => $_key,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0640',
  }

}
