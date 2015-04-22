#
define uhosting::resources::site (
  $data,
) {

  $sitedata    = $data[$name]
  $homedir     = "/var/www/${name}"
  $webroot     = "${homedir}/public_html"
  $vassals_dir = '/etc/uwsgi-emperor/vassals'

  # compose server_names
  if $sitedata['server_names'] {
    validate_array($sitedata['server_names'])
    if $::vagrant {
      $suffix = [ ".${::fqdn}", ".vagrant.dev" ]
    } else {
      $suffix = [ ".${::fqdn}" ]
    }
    $supre = {
      'suffix' => $suffix,
      'prefix' => [ 'www.' ],
    }
    $server_names = generate_server_names($sitedata['server_names'],$supre)
  } else {
    fail("'server_names' FOR ${name} IS NOT CONFIGURED")
  }

  if $sitedata['ensure'] {
    validate_re($sitedata['ensure'], '^present|absent$')
    $ensure = $sitedata['ensure']
  } else {
    $ensure = 'present'
  }

  if $sitedata['uid'] {
    if ! is_integer($sitedata['uid']) {
      fail('uid is not an integer')
    }
    $uid = $sitedata['uid']
  } else {
    $uid = undef
  }

  if $sitedata['uwsgi_params'] {
    validate_hash($sitedata['uwsgi_params'])
    $uwsgi_params = $sitedata['uwsgi_params']
  }

  if $sitedata['system_packages'] {
    validate_array($sitedata['system_packages'])
    ensure_packages($sitedata['system_packages'])
  }

  ## Site user account
  identity::user { $name:
    ensure  => $ensure,
    uid     => $uid,
    comment => "Site account for ${name}",
    shell   => '/usr/sbin/nologin',
    home    => $homedir,
    groups  => [ 'www-data' ],
  } ->
  # create webroot
  file { $webroot:
    ensure => directory,
    owner  => $name,
    group  => $name,
  }

  # do we need this stack_type?
  # maybe we could add $uwsgi_plugin to the sitedata hash
  # or use stack_type static vs dynamic to chose if there should be
  # a vassal
  case $sitedata['stack_type'] {
    'static': {
      $vhost_defaults = {
        ensure               => $ensure,
        www_root             => $webroot,
        server_name          => $server_names,
        index_files          => ['index.html'],
        use_default_location => true,
      }
    }
    'uwsgi': {
      case $sitedata['uwsgi_plugin'] {
        'php': {
          $plugins = 'php'
          # TODO add some php5enmod logic
          if $uwsgi_params {
            $vassal_params = $uwsgi_params
          }
          file { "${vassals_dir}/${name}.ini":
            content => template('uhosting/uwsgi_vassal.ini.erb')
          }
          $vhost_defaults = {
            ensure               => $ensure,
            www_root             => $webroot,
            server_name          => $server_names,
            index_files          => ['index.php'],
            use_default_location => true,
            location_raw_append  => [
              'include uwsgi_params;',
              'try_files $uri /index.php =404;',
              'uwsgi_modifier1 14;',
              "uwsgi_pass unix:/run/uwsgi/${name}.socket;",
             ],
          }
        }
        'ruby': {
          $plugins = 'rack'
          if ! $sitedata['rack'] {
            fail("MUST DEFINE 'rack' on ${name}")
          } else {
            validate_absolute_path($sitedata['rack'])
          }
          $vassal_params_default = {
            'rack' => $sitedata['rack'],
          }
          if $uwsgi_params {
            $vassal_params = merge($vassal_params_default,$uwsgi_params)
          } else {
            $vassal_params = $vassal_params_default
          }
          file { "${vassals_dir}/${name}.ini":
            content => template('uhosting/uwsgi_vassal.ini.erb')
          }
          $vhost_defaults = {
            ensure               => $ensure,
            www_root             => $webroot,
            server_name          => $server_names,
            index_files          => ['index.html'],
            use_default_location => true,
            location_raw_append  => [
              'include uwsgi_params;',
              'uwsgi_modifier1 7;',
              "uwsgi_pass unix:/run/uwsgi/${name}.socket;",
            ],
          }
        }
        'python': {
          $plugins = 'python'
          if ! $sitedata['wsgi-file'] {
            fail("MUST DEFINE 'wsgi-file' on ${name}")
          } else {
            validate_absolute_path($sitedata['wsgi-file'])
          }
          $vassal_params_default = {
            'wsgi-file' => $sitedata['wsgi-file'],
          }
          if $uwsgi_params {
            $vassal_params = merge($vassal_params_default,$uwsgi_params)
          } else {
            $vassal_params = $vassal_params_default
          }
          file { "${vassals_dir}/${name}.ini":
            content => template('uhosting/uwsgi_vassal.ini.erb')
          }
          $vhost_defaults = {
            ensure               => $ensure,
            www_root             => $webroot,
            server_name          => $server_names,
            index_files          => ['index.html'],
            use_default_location => true,
            location_raw_append  => [
              'include uwsgi_params;',
              "uwsgi_pass unix:/run/uwsgi/${name}.socket;",
            ],
          }
        }
        default: {
          fail("UWSGI PLUGIN UNKNOWN")
        }
      }
    }
    default: {
      fail("STACKTYPE UNKNOWN")
    }
  }

  # $sitedata['vhost_params'] can be empty, so we merge it here
  # and don't use it as default value for create_resources
  $vhost_params = merge($vhost_defaults,$sitedata['vhost_params'])
  $vhost_resource = { "${name}" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)
  if $sitedata['vhost_locations'] {
    $location_defaults = {
      vhost => $name
    }
    create_resources('::nginx::resource::location',$sitedata['vhost_locations'],$location_defaults)
  }

}
