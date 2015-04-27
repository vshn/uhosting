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

  # ensure handling
  if $sitedata['ensure'] {
    validate_re($sitedata['ensure'], '^present|absent$')
    $ensure = $sitedata['ensure']
  } else {
    $ensure = 'present'
  }

  # uid checking
  if $sitedata['uid'] {
    if ! is_integer($sitedata['uid']) {
      fail('uid is not an integer')
    }
    $uid = $sitedata['uid']
  } else {
    $uid = undef
  }

  # uwsgi parameters
  if $sitedata['uwsgi_params'] {
    validate_hash($sitedata['uwsgi_params'])
    $uwsgi_params = $sitedata['uwsgi_params']
  }

  # system packages
  # TODO: really needed?
  if $sitedata['system_packages'] {
    validate_array($sitedata['system_packages'])
    ensure_packages($sitedata['system_packages'])
  }

  # ssl certificate handling
  if $sitedata['ssl_cert'] {
    validate_absolute_path($sitedata['ssl_cert'])
    $ssl_cert = $sitedata['ssl_cert']
    if $sitedata['ssl_key'] {
      validate_absolute_path($sitedata['ssl_key'])
      $ssl_key = $sitedata['ssl_key']
    } else {
      fail('A CERTIFICATE WITHOUT A KEY MAKES NO SENSE')
    }
    $ssl = true
    $rewrite_to_https = true
    $hsts = { 'Strict-Transport-Security' => '"max-age=63072000; includeSubdomains; preload"' }
  } else {
    $ssl_cert = undef
    $ssl_key = undef
    $ssl = false
    $rewrite_to_https = false
    $hsts = undef
  }

  # vhost default parameters
  $vhost_global_defaults = {
    ensure               => $ensure,
    www_root             => $webroot,
    server_name          => $server_names,
    index_files          => ['index.html'],
    use_default_location => true,
    ssl                  => $ssl,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    rewrite_to_https     => true,
    ssl_protocols        => 'TLSv1 TLSv1.1 TLSv1.2',
    ssl_ciphers          => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
    ssl_stapling         => true,
    ssl_stapling_verify  => true,
    add_header           => $hsts,
  }

  ## Site user account
  identity::user { $name:
    ensure  => $ensure,
    uid     => $uid,
    comment => "Site account for ${name}",
    shell   => '/usr/sbin/nologin',
    home    => $homedir,
    groups  => [ 'www-data' ],
    require => File['/var/www'],
  } ->
  # create webroot
  file { $webroot:
    ensure => directory,
    owner  => $name,
    group  => $name,
  }

  case $sitedata['stack_type'] {
    'static': {
      include uhosting::profiles::nginx
    }
    'uwsgi': {
      include uhosting::profiles::nginx
      include uhosting::profiles::uwsgi
      case $sitedata['uwsgi_plugin'] {
        'php': {
          include uhosting::profiles::uwsgi::php
          $plugins = 'php'
          # TODO add some php5enmod logic
          if $uwsgi_params {
            $vassal_params = $uwsgi_params
          }
          file { "${vassals_dir}/${name}.ini":
            content => template('uhosting/uwsgi_vassal.ini.erb'),
            require => Class['uhosting::profiles::uwsgi::php'],
          }
          $vhost_defaults = {
            index_files          => ['index.php'],
            location_raw_append  => [
              'include uwsgi_params;',
              'try_files $uri /index.php =404;',
              'uwsgi_modifier1 14;',
              "uwsgi_pass unix:/run/uwsgi/${name}.socket;",
             ],
          }
        }
        'ruby': {
          include uhosting::profiles::uwsgi::ruby
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
            content => template('uhosting/uwsgi_vassal.ini.erb'),
            require => Class['uhosting::profiles::uwsgi::php'],
          }
          $vhost_defaults = {
            location_raw_append  => [
              'include uwsgi_params;',
              'uwsgi_modifier1 7;',
              "uwsgi_pass unix:/run/uwsgi/${name}.socket;",
            ],
          }
        }
        'python': {
          include uhosting::profiles::uwsgi::python
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
            content => template('uhosting/uwsgi_vassal.ini.erb'),
            require => Class['uhosting::profiles::uwsgi::php'],
          }
          $vhost_defaults = {
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
  $vhost_defaults1 = merge($vhost_global_defaults,$vhost_defaults)
  $vhost_params = merge($vhost_defaults1,$sitedata['vhost_params'])
  $vhost_resource = { "${name}" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)

  # locations
  if $sitedata['vhost_locations'] {
    $location_defaults = {
      vhost    => $name,
      ssl      => $ssl,
      ssl_only => $ssl,
    }
    create_resources('::nginx::resource::location',$sitedata['vhost_locations'],$location_defaults)
  }

  case $sitedata['database'] {
    'mariadb': {
      include uhosting::profiles::mariadb
    }
    'postgresql': {
      include uhosting::profiles::postgresql
    }
  }

}
