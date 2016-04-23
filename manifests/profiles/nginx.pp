# == Class: uhosting::profiles::nginx
#
# Installs and manages Nginx webserver (nginx-extras)
# It also opens firewall settings
#
# === Parameters
#
# [*nginx_ppa*]
#   If true the Nginx mainline PPA will get used
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
class uhosting::profiles::nginx (
  $nginx_ppa = false,
) inherits ::uhosting {

  ## Create and manage directories
  file {
    '/var/www':
      ensure => directory;
  }

  if $nginx_ppa {
    apt::source { 'nginx_ppa':
      comment     => 'Nginx Mainline PPA',
      location    => 'http://ppa.launchpad.net/nginx/development/ubuntu',
      release     => $::lsbdistcodename,
      repos       => 'main',
      key         => {
        'id' => '8B3981E7A6852F782CC4951600A6F0A3C300EE8C',
        'server' => 'hkp://keyserver.ubuntu.com:80',
      },
      include     => {
        'src' => false,
        'deb' => true,
      }
    }
  }

  ## Install and configure Nginx
  if $::uhosting::redirects {
    file {
      '/etc/nginx/redirects.conf':
        content => template('uhosting/nginx_redirects.conf.erb');
    }
    file {
      '/etc/nginx/sites-enabled/01_catchall.conf':
        content => template('uhosting/nginx_01_catchall.conf.erb');
    }
    $http_cfg_append = {
      'include' => '/etc/nginx/redirects.conf',
    }
  } else {
    $http_cfg_append = undef
  }

  class { '::nginx::config':
    vhost_purge            => true,
    names_hash_bucket_size => 128,
    http_cfg_append        => $http_cfg_append,
  }

  class { '::nginx':
    package_name      => 'nginx-extras',
    configtest_enable => true,
  }

  ## Generate unique DH params for this server
  exec { 'generate_dhparams':
    command => '/usr/bin/openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048',
    creates => '/etc/ssl/certs/dhparam.pem',
  }

  ## Firewall settings
  firewall {
    '020 open HTTP and HTTPS IPv4':
      dport  => [80,443],
      proto  => 'tcp',
      action => 'accept';
    '020 open HTTP and HTTPS IPv6':
      dport    => [80,443],
      proto    => 'tcp',
      action   => 'accept',
      provider => 'ip6tables';
  }

}
