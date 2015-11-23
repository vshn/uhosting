# == Class: uhosting::profiles::uwsgi::ruby
#
# Installs and manages Ruby together with uWSGI
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
class uhosting::profiles::uwsgi::ruby {

  package {
    'uwsgi-plugin-rack-ruby1.9.1':
      ensure  => installed,
      require => Package['uwsgi-core'];
    'ruby-rack':
      ensure  => installed;
  }

  class { '::ruby': }

}
