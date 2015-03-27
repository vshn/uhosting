#
define uhosting::resources::nginx_vhost (
  $data,
) {

  $sitedata    = $data[$name]
  $homedir     = "/var/www/${name}"
  $webroot     = "${homedir}/public_html"
  $vassals_dir = '/etc/uwsgi-emperor/vassals'

  # compose server_names
  if $sitedata['server_names'] {
    validate_array($sitedata['server_names'])
    # TODO: create custom function for suffix and prefix at the same time
    $server_names_orig = $sitedata['server_names']
    $server_names_suffixed = suffix($server_names_orig, ".${::fqdn}")
    $server_names_prefixed = prefix($server_names_orig, "www.")
    $server_names_union1 = union($server_names_prefixed,$server_names_suffixed)
    $server_names = union($server_names_orig,$server_names_union1)
  } else {
    fail("'server_names' FOR ${name} IS NOT CONFIGURED")
  }

  if $sitedata['ensure'] {
    validate_re($sitedata['ensure'], '^present|absent$')
    $ensure = $sitedata['ensure']
  } else {
    $ensure = 'present'
  }

  # create webroot
  file { [ $homedir, $webroot ]:
    ensure => directory,
    #owner  => $name,
    #group  => $name,
  }

  case $sitedata['stacktype'] {
    'static': {
      ::nginx::resource::vhost { $name:
        ensure               => $ensure,
        www_root             => $webroot,
        server_name          => $server_names,
        index_files          => ['index.html'],
        use_default_location => true,
      }
    }
    'php': {
      # TODO ::nginx::resource::vhost { $name:
      file { "${vassals_dir}/${name}.ini":
        content => template('uhosting/uwsgi_php.ini.erb')
      }
    }
    default: {
      fail("STACKTYPE UNKNOWN")
    }
  }

}
