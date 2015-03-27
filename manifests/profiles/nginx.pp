#
class uhosting::profiles::nginx inherits ::uhosting {

  # get all sites coming from the main class
  $site_names = keys($uhosting::sites)

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

  # create vhosts
  resources::nginx_vhost { $site_names:
    data => $uhosting::sites,
  }

  # TODO: create users and groups. maybe virtual

}
