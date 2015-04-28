#
class uhosting::profiles::nginx inherits ::uhosting {

  ## Create and manage directories
  file {
    '/var/www':
      ensure => directory;
  }

  ## Install and configure Nginx
  if $::uhosting::redirects {
    file {
      '/etc/nginx/redirects.conf':
        content => template('uhosting/nginx_redirects.conf.erb');
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
