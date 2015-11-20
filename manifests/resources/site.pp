#
define uhosting::resources::site (
  $data,
) {

  $sitedata    = $data[$name]
  $homedir     = "/var/www/${name}"
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
    $server_names_generated = generate_server_names($sitedata['server_names'],$supre)
    if $sitedata['server_names_extra'] {
      validate_array($sitedata['server_names_extra'])
      $server_names = union($server_names_generated,$sitedata['server_names_extra'])
    } else {
      $server_names = $server_names_generated
    }
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

  # shell of site user
  if $sitedata['siteuser_shell'] {
    $siteuser_shell = $sitedata['siteuser_shell']
  } else {
    $siteuser_shell = '/bin/bash'
  }

  # alternative webroot
  if $sitedata['webroot'] {
    $webroot = $sitedata['webroot']
  } else {
    $webroot = "${homedir}/public_html"
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

  # environment variables
  if $sitedata['env_vars'] {
    validate_hash($sitedata['env_vars'])
    $env_vars = $sitedata['env_vars']
  }
  if $sitedata['db_user'] {
    $db_user = $sitedata['db_user']
  } else {
    $db_user = $name
  }
  if $sitedata['db_name'] {
    $db_name = $sitedata['db_name']
  } else {
    $db_name = $name
  }
  $default_env_vars = {
    'sitename' => $name,
    'stacktype' => $sitedata['stack_type'],
    'db_name' => $db_name,
    'db_user' => $db_user,
    'db_password' => $sitedata['db_password'],
    'db_host' => 'localhost',
  }
  $_env_vars = merge($default_env_vars,$env_vars)

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
    if $sitedata['ssl_rewrite_to_https'] == false {
      $rewrite_to_https = false
    } else {
      $rewrite_to_https = true
    }
    $ssl = true
    $hsts = { 'Strict-Transport-Security' => '"max-age=31536000"' }
    $ssl_dhparam = '/etc/ssl/certs/dhparam.pem'
  } else {
    $ssl_cert = undef
    $ssl_key = undef
    $ssl = false
    $rewrite_to_https = false
    $hsts = undef
    $ssl_dhparam = undef
  }

  # vhost default parameters
  $vhost_global_defaults = {
    ensure               => $ensure,
    ipv6_enable          => true,
    ipv6_listen_options  => '',
    www_root             => $webroot,
    server_name          => $server_names,
    index_files          => ['index.html'],
    use_default_location => true,
    ssl                  => $ssl,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    ssl_dhparam          => $ssl_dhparam,
    rewrite_to_https     => $rewrite_to_https,
    ssl_protocols        => 'TLSv1 TLSv1.1 TLSv1.2',
    ssl_ciphers          => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
    #ssl_stapling        => true, TODO needs more work: http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_stapling_verify
    #ssl_stapling_verify => true,
    add_header           => $hsts,
  }

  ## Site user account
  if $sitedata['ssh_keys'] {
    $_groups = [ 'www-data', 'sshlogin' ]
  } else {
    $_groups = [ 'www-data' ]
  }
  identity::user { $name:
    ensure   => $ensure,
    uid      => $uid,
    comment  => "Site account for ${name}",
    shell    => $siteuser_shell,
    home     => $homedir,
    groups   => $_groups,
    ssh_keys => $sitedata['ssh_keys'],
    require  => File['/var/www'],
  } ->
  # create webroot
  file { $webroot:
    ensure => directory,
    owner  => $name,
    group  => $name,
  } ->
  file { "${homedir}/.bash_aliases":
    ensure  => $ensure,
    content => template('uhosting/bash_envvars.erb'),
    owner   => $name,
    group   => $name,
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
          include uhosting::profiles::php
          $plugins = 'php'
          # TODO add some php5enmod logic
          $vassal_params_default = {
            'static-skip-ext' => '.php',
            'check-static'    => $webroot,
            'php-docroot'     => $webroot,
            'chdir'           => $webroot,
            'php-allowed-ext' => '.php',
            'php-set'         => "error_log=/var/log/php/${name}.log",
            'php-index'       => 'index.php',
          }
          if $uwsgi_params {
            $vassal_params = merge($vassal_params_default,$uwsgi_params)
          } else {
            $vassal_params = $vassal_params_default
          }
          file { "${vassals_dir}/${name}.ini":
            content => template('uhosting/uwsgi_vassal.ini.erb'),
            require => Class['uhosting::profiles::php'],
          }
          $vhost_defaults = {
            index_files         => ['index.php'],
            try_files           => [ '$uri', '$uri/', '/index.php', '/index.html', '=404' ],
            location_raw_append => [
              'include uwsgi_params;',
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
            require => Class['uhosting::profiles::uwsgi::ruby'],
          }
          $vhost_defaults = {
            location_raw_append  => [
              'include uwsgi_params;',
              'uwsgi_modifier1 7;',
              'if (!-f $request_filename) {',
              "  uwsgi_pass unix:/run/uwsgi/${name}.socket;",
              '}',
            ],
          }
        }
        'python': {
          include uhosting::profiles::uwsgi::python
          $plugins = 'python'
          if $sitedata['pip_packages'] {
            $virtualenv_dir = "${homedir}/virtualenv"
            $pips = prefix(keys($sitedata['pip_packages']),"${name}-")
            python::virtualenv { $virtualenv_dir:
              ensure => $ensure,
              owner  => $name,
              group  => $name,
            } ->
            uhosting::helper::python_pip { $pips:
              ensure       => $ensure,
              orig_name    => $name,
              virtualenv   => $virtualenv_dir,
              pip_packages => $sitedata['pip_packages'],
            }
          }
          if $uwsgi_params {
            $vassal_params = $uwsgi_params
          }
          file { "${vassals_dir}/${name}.ini":
            content => template('uhosting/uwsgi_vassal.ini.erb'),
            require => Class['uhosting::profiles::uwsgi::python'],
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
    'phpfpm': {
      include uhosting::profiles::nginx
      include uhosting::profiles::supervisord
      include uhosting::profiles::php
      $fpm_socket = "/var/run/php5-fpm-${name}.sock"
      $vhost_defaults = {
        index_files => [ 'index.php' ],
        try_files   => [ '$uri', '$uri/', '/index.php', '/index.html', '=404' ],
        fastcgi     => "unix:${fpm_socket}",
      }
      # PHP-FPM pool
      $default_php_flags = {
        'display_errors'         => 'off',
        'display_startup_errors' => 'off',
      }
      if $sitedata['php_flags'] {
        validate_hash($sitedata['php_flags'])
        $_php_flags = merge($default_php_flags,$sitedata['php_flags'])
      } else {
        $_php_flags = $default_php_flags
      }
      # php_values
      $default_php_values = {
      }
      if $sitedata['php_values'] {
        validate_hash($sitedata['php_values'])
        $_php_values = merge($default_php_values,$sitedata['php_values'])
      } else {
        $_php_values = $default_php_values
      }
      # php_admin_values
      if $sitedata['php_admin_values'] {
        validate_hash($sitedata['php_admin_values'])
        $_php_admin_values = $sitedata['php_admin_values']
      } else {
        $_php_admin_values = {}
      }
      # php_admin_flags
      if $sitedata['php_admin_flags'] {
        validate_hash($sitedata['php_admin_flags'])
        $_php_admin_flags = $sitedata['php_admin_flags']
      } else {
        $_php_admin_flags = {}
      }
      $fpm_pm                   = 'dynamic'
      $fpm_listen_backlog       = '-1'
      $fpm_max_children         = 50
      $fpm_start_servers        = 5
      $fpm_min_spare_servers    = 5
      $fpm_max_spare_servers    = 35
      $fpm_max_requests         = 0 # no respawning
      $fpm_process_idle_timeout = undef
      phpfpm_pool { $name:
        ensure                   => $ensure,
        fpm_pm                   => $fpm_pm,
        fpm_socket               => $fpm_socket,
        fpm_listen_backlog       => $fpm_listen_backlog,
        fpm_max_children         => $fpm_max_children,
        fpm_start_servers        => $fpm_start_servers,
        fpm_min_spare_servers    => $fpm_min_spare_servers,
        fpm_max_spare_servers    => $fpm_max_spare_servers,
        fpm_max_requests         => $fpm_max_requests,
        fpm_process_idle_timeout => $fpm_process_idle_timeout,
        php_admin_values         => $_php_admin_values,
        php_admin_flags          => $_php_admin_flags,
        php_flags                => $_php_flags,
        php_values               => $_php_values,
        env_variables            => $_env_vars,
        require                  => Class['uhosting::profiles::php'],
      }
    }
    default: {
      fail("STACKTYPE UNKNOWN")
    }
  }

  # $sitedata['vhost_params'] can be empty, so we merge it here
  # and don't use it as default value for create_resources
  $vhost_defaults1 = merge($vhost_global_defaults,$vhost_defaults)

  # if an app_profile is defined, use it
  if $sitedata['app_profile'] {
    case $sitedata['app_profile'] {
      'owncloud': {
        # TODO: uwsgi_params, system_packages, database, uwsgi_plugin
        # TODO: create defined type and migrate settings to there
        #::uhosting::app::owncloud { $name:
        #}
        # vhost settings
        $app_vhost_params = {
          use_default_location => false,
          www_root             => $webroot,
          rewrite_rules        => [
            '^/caldav(.*)$ /remote.php/caldav$1 redirect',
            '^/carddav(.*)$ /remote.php/carddav$1 redirect',
            '^/webdav(.*)$ /remote.php/webdav$1 redirect',
          ],
        }
        $vhost_params = merge($vhost_defaults1,$app_vhost_params)

        # location settings
        ::nginx::resource::location { "${name}-root":
          vhost         => $name,
          ssl           => $ssl,
          ssl_only      => $ssl,
          location      => '/',
          www_root      => $webroot,
          rewrite_rules => [
            '^/.well-known/host-meta /public.php?service=host-meta last',
            '^/.well-known/host-meta.json /public.php?service=host-meta-json last',
            '^/.well-known/carddav /remote.php/carddav/ redirect',
            '^/.well-known/caldav /remote.php/caldav/ redirect',
            '^(/core/doc/[^\/]+/)$ $1/index.html',
          ],
          try_files     => ['$uri','$uri/','/index.php'],
        }
        ::nginx::resource::location { "${name}-php":
          vhost               => $name,
          ssl                 => $ssl,
          ssl_only            => $ssl,
          location            => '~ \.php(?:$|/)',
          uwsgi               => "unix:/run/uwsgi/${name}.socket",
          location_cfg_append => { 'uwsgi_modifier1' => '14' },
        }
        ::nginx::resource::location { "${name}-denies":
          vhost               => $name,
          ssl                 => $ssl,
          ssl_only            => $ssl,
          location            => '~ ^/(?:\.htaccess|data|config|db_structure\.xml|README)',
          location_custom_cfg => { 'deny' => 'all' },
        }

      }
      default: { fail("no such app_profile available: ${$sitedata['app_profile']}") }
    }
  } else {
    # vhost settings
    $vhost_params = merge($vhost_defaults1,$sitedata['vhost_params'])

    # location settings
    if $sitedata['vhost_locations'] {
      $location_defaults = {
        vhost    => $name,
        ssl      => $ssl,
        ssl_only => $ssl,
      }
      create_resources('::nginx::resource::location',
        prefix($sitedata['vhost_locations'],"${name}-")
        ,$location_defaults)
    }
  }

  # Create Nginx vhost
  $vhost_resource = { "${name}" => $vhost_params }
  create_resources('::nginx::resource::vhost',$vhost_resource)


  case $sitedata['database'] {
    'mariadb': {
      include uhosting::profiles::mariadb
    }
    'postgresql': {
      include uhosting::profiles::postgresql
    }
  }

}
