#
class uhosting::profiles::nginx inherits ::uhosting {

  # Create and manage directories
  file {
    '/var/www':
      ensure => directory;
  }

  class { '::nginx::config':
    vhost_purge     => true,
    names_hash_bucket_size => 128,
  }

  class { '::nginx':
    package_name => 'nginx-extras',
  }

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
