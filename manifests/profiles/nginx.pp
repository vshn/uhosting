#
class uhosting::profiles::nginx {

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

}
