# == Define: uhosting::resources::site
#
# Creates sites (vhost, app server).
#
# === Parameters
#
# [*data*]
#   Hash of site parameters. For a detailed description see README.
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::resources::site (
  $data,
) {

  #############################################################################
  ### Prepare vars for later usage
  #############################################################################

  $sitedata    = $data[$name]
  $homedir     = "/var/www/${name}"
  $vassals_dir = '/etc/uwsgi-emperor/vassals'
  $socket_path = '/var/lib/uhosting'

  ## Handling of ensure parameter

  if $sitedata['ensure'] {
    validate_re($sitedata['ensure'], '^present|absent$')
    $ensure = $sitedata['ensure']
  } else {
    $ensure = 'present'
  }

  ## Generate server_names for Nginx vhost

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

  ## Shell definition for site user

  if $sitedata['siteuser_shell'] {
    $siteuser_shell = $sitedata['siteuser_shell']
  } else {
    $siteuser_shell = '/bin/bash'
  }

  ## SSH key preparation (add user to sshlogin group)

  if $sitedata['ssh_keys'] {
    validate_hash($sitedata['ssh_keys'])
    $_groups = [ 'www-data', $::uhosting::sshlogin_group ]
  } else {
    $_groups = [ 'www-data' ]
  }

  ## Prepare webroot

  if $sitedata['webroot'] {
    $webroot = $sitedata['webroot']
  } else {
    $webroot = "${homedir}/public_html"
  }

  ## Validate UID of site user if defined

  if $sitedata['uid'] {
    if ! is_integer($sitedata['uid']) {
      fail('uid is not an integer')
    }
    $uid = $sitedata['uid']
  } else {
    $uid = undef
  }

  ## Validate uwsgi parameters

  if $sitedata['uwsgi_params'] {
    validate_hash($sitedata['uwsgi_params'])
    $uwsgi_params = $sitedata['uwsgi_params']
  }

  ## Validate and prepare database settings

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

  ## Validate and prepare environment variables

  if $sitedata['env_vars'] {
    validate_hash($sitedata['env_vars'])
    $env_vars = $sitedata['env_vars']
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

  ## Handle SSL certificate settings

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

  ## Define default vhost parameters

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

  #############################################################################
  ### Create site user account
  #############################################################################

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

  #############################################################################
  ### Site definition
  #############################################################################

  ## Use a pre-defined app configuration if an app is defined
  ## else allow custom configuration of the site definition

  if ($sitedata['app']) and ($sitedata['stack_type']) {
    fail('app and stack_type cannot be used together')
  }

  if $sitedata['app'] {
    $_app = $sitedata['app']
    if $sitedata['app_settings'] {
      validate_hash($sitedata['app_settings'])
      $_app_settings = $sitedata['app_settings']
    } else {
      $_app_settings = {}
    }
    $_app_params = {
      "${name}" => {
        'app_settings' => $_app_settings,
        'ssl' => $ssl,
        'vassals_dir' => $vassals_dir,
        'vhost_defaults' => $vhost_global_defaults,
        'webroot' => $webroot,
      }
    }
    create_resources("uhosting::app::${_app}", $_app_params)
  } else {
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
                "uwsgi_pass unix:${socket_path}/${name}.socket;",
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
                "  uwsgi_pass unix:${socket_path}/${name}.socket;",
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
                "uwsgi_pass unix:${socket_path}/${name}.socket;",
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
        $fpm_socket = "${socket_path}/php5-fpm-${name}.sock"
        $vhost_defaults = {
          index_files => [ 'index.php' ],
          try_files   => [ '$uri', '$uri/', '=404' ],
        }
        # Nginx Locations
        nginx::resource::location { 'default_php':
          vhost              => $name,
          ssl                => $ssl,
          location           => '~ [^/]\.php(/|$)',
          www_root           => $webroot,
          try_files          => [ '$uri', '=404' ],
          fastcgi            => "unix:${fpm_socket}",
          fastcgi_split_path => '^(.+?\.php)(/.*)$',
          fastcgi_param      => {
            'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name',
          },
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
        uhosting::resources::phpfpm_pool { $name:
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
          php_version              => $::uhosting::profiles::php::php_version,
          env_variables            => $_env_vars,
          require                  => Class['::php'],
        }
      }
      'nodejs': {
        include uhosting::profiles::nginx
        include uhosting::profiles::supervisord
        include uhosting::profiles::nodejs
        if $sitedata['nodejs_app'] {
          $nodejs_app = $sitedata['nodejs_app']
        } else {
          $nodejs_app = "${homedir}/nodejs/index.js"
        }
        if $sitedata['nodejs_version'] {
          $nodejs_version = $sitedata['nodejs_version']
        }
        file { "${homedir}/nodejs":
          ensure => directory,
          owner  => $name,
          group  => $name,
        }
        if $sitedata['nodejs_packages'] {
          $_packages = prefix($sitedata['nodejs_packages'], "${name}-")
          uhosting::resources::nodejs_package { $_packages:
            user    => $name,
            homedir => $homedir,
          }
        }
        uhosting::resources::nodejs_worker { $name:
          ensure  => $ensure,
          version => $nodejs_version,
          app     => $nodejs_app,
        }
        if $sitedata['nodejs_disable_vhost'] {
          $vhost_defaults = {
            ensure => absent,
          }
        } else {
          $vhost_defaults = {
            use_default_location  => false,
          }
          validate_integer($sitedata['nodejs_port'], 65535, 1024)
          nginx::resource::location { '/':
            vhost => $name,
            proxy => "http://127.0.0.1:${sitedata['nodejs_port']}",
            ssl   => $ssl,
            proxy_set_header => [ 'Host $host', 
                                  'X-Real-IP $remote_addr', 
                                  'X-Forwarded-For $proxy_add_x_forwarded_for',
                                  'X-Forwarded-Proto $scheme',
                                  'X-SSL $https' ]
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

    # Create Nginx vhost
    $vhost_resource = { "${name}" => $vhost_params }
    create_resources('::nginx::resource::vhost',$vhost_resource)
  }

  #############################################################################
  ### Database definition
  #############################################################################

  if $sitedata['database'] {
    case $sitedata['database'] {
      'mariadb': {
        include uhosting::profiles::mariadb
      }
      'postgresql': {
        include uhosting::profiles::postgresql
      }
      default: {
        fail("Database type ${$sitedata['database']} unknown!")
      }
    }
  }

  #############################################################################
  ### Site cron definition
  #############################################################################

  if $sitedata['crons'] {
    validate_hash($sitedata['crons'])
    # as we do not allow to override the user, we need a helper
    $_crons = keys($sitedata['crons'])
    ::uhosting::resources::cron { $_crons:
      data => $sitedata['crons'],
      user => $name,
    }
  }
}
