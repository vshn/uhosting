#### Table of Contents

1. [Overview](#overview)
1. [Module Description - What the module does and why it is useful](#module-description)
1. [Setup - The basics of getting started with uhosting](#setup)
    * [What uhosting affects](#what-uhosting-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with uhosting](#beginning-with-uhosting)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Parameters for uhosting::sites](#parameters-for-uhostingsites)
    * [SSL Configuration](#ssl-configuration)
    * [Environment Variables](#environment-variables)
    * [Redirects](#redirects)
    * [DNS Server](#dns-server)
1. [App Profiles](#app-profiles)
1. [Stack Types](#stack-types)
    * [Stack type static](#stack-type-static)
    * [Stack type uwsgi](#stack-type-uwsgi)
    * [Stack type phpfpm](#stack-type-phpfpm)
    * [Stack type nodejs](#stack-type-nodejs)
1. [Vagrant specials](#vagrant-specials)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Known Issues](#knownissues)
1. [Development](#development)

## Overview

Easy webhosting with a collection of profiles and easy resource creation.

## Module Description

This module has a lot of opinionated content. It reflects our current idea of a simple,
multi language hosting configuration.

It serves two main purposes:

* A local Vagrant machine to try out webapplications in the same environment
  as it could later run on
* A configuration mechanism to define websites, including application specific
  configuration, database management, and so on.

Based on the following key technologies:

* Nginx
* uWSGI or PHP-FPM
* MariaDB
* PostgreSQL
* Knot DNS
* Ubuntu 14.04 Server

It also brings so called app profiles to pre-configure a virtual host for a specific app.
Have a look under [manifests/app](/vshn/uhosting/tree/master/manifests/app) to see all
available app profiles.

## Setup

### What uhosting affects

* Configuration and management of all services included in this module

### Setup Requirements

A working hiera configuration is needed for full pleasure.

The module depends on a lot of third party modules. Have a look at `vagrant/Puppetfile` to find
out which ones. Here is a list of the most important ones:

* [nginx](https://forge.puppetlabs.com/jfryman/nginx)
* [php](https://forge.puppetlabs.com/mayflower/php)
* [mysql](https://forge.puppetlabs.com/puppetlabs/mysql)
* [staging](https://forge.puppetlabs.com/nanliu/staging)

### Beginning with uhosting

Just include the `uhosting` class and define a basic site in the `uhosting::sites` hash:

```YAML
uhosting::sites:
  mysite_com:
    server_names:
      - 'mysite.com'
    stack_type: 'static'
```

This example sets up Nginx with a virtual server for mysite.com, serving static pages from
`/var/www/mysite_com/public_html`.

## Usage

Including the `uhosting` class won't do anything but validating the `uhosting::sites` hash and
calling the `resources::site` type using some stdlib-fu.
The real magic happens in the `resources::site` class where it uses the parameters found in
`uhosting::sites` to create the needed configuration.

All components are installed only when needed. So when there is no site defined using a
database, it won't be installed. As soon as a site uses a database, the specific database
is installed and configured. This applies also to Nginx, uWSGI, the language stack, Knot etc.

## Reference

### Parameters for `uhosting::sites`

* **!**: mandatory
* **x**: not in use when using an app profile

Choose between `stack_type` and `app`, both cannot be used!

* ! **_key** (string): The key of the hash defines the identifier of the site
  and will be used to f.e. create a system user. Do not change it once it is set and Puppet has done it's job!
* ! **server_names** (array of strings): Virtual domain names. `www.` will be added automatically
* !x **stack_type** (string): Type of the hosting stack. Possible values: `static`, `uwsgi`, `unicorn` and `phpfpm`. If the app parameter is set, this one has no use.
  If the stack type is `uwsgi`, the parameter `uwsgi_plugin` needs to be configured too
  Unicorn should be installed via gem / Gemfile of your app. Set ruby version with rvm for the app user
* **app** (string): Name of an app profile to use. If this parameter is set, some of the other parameters have no affect.
* **app_settings** (hash of strings): Application specific parameters used in the app profile. See header of the corresponding manifest for a parameter description.
* **basic_auth** (bool): if true the whole vhost will be basic auth protected
* **basic_auth_file** (absolute path): custom .htpasswd file location. Default: `/var/www/${name}/.htpasswd`, use `htpasswd -c /var/www/${name}/.htpasswd <username>` to create a user
* **crons** (hash of strings): Cronjobs to run as the site user. For parameters see [cron](https://docs.puppetlabs.com/references/latest/type.html#cron). The username is enforced!
* **database** (string): Type of database to manage for this site
* **db_name** (string): If not set, the db name will be the same as the key
* **db_password** (string): Plain text password to set for this site
* **db_user** (string): If not set, the db user will be the same as the key
* **ensure** (present/absent). Default is present. When set to absent all resources beloging to this site will get deleted
* x **env_vars** (hash of strings): Additional environment variables to set
* **ruby_env** (string): Sets unicorn / rack environment for ruby / rails
* **ruby_version** (string): Mainly used to build up path for rails / gems
* **rvm** (bool): Set true to install RVM and enable siteuser to use rvm (adds user to rvm group)
* **server_names_extra** (array of strings): These server names will be added to the `server_names` and the generated ones
* **siteuser_shell** (path): Defines the shell of the site user. Default: `/bin/bash`
* **ssh_keys**: SSH keys to attach to the site user to allow SSH login into the site user
* **ssl_cert** (path): Path to the ssl certificate on the server. This activates SSL on the vhost
* **ssl_key** (path): Path to the ssl key on the server
* **ssl_rewrite_to_https**: Redirects HTTP to HTTPS
* **uid** (integer): UID of the site user. Default: Automatically chosen
* x **uwsgi_params** (hash): Can be used to define additional uWSGI vassal settings or overwrite the default onces
* x **uwsgi_plugin** (string): uWSGI plugin to load for this site
* x **vhost_locations** (hash): Parameters for the `nginx::resource::location` type. Passed to `create_resources`
* x **vhost_params** (hash): Parameters for the `nginx::resource::vhost` type. Can be used to add additional settings or overwrite the defaults
* x **webroot** (path): Webroot of the site. Default: `/var/www/${name}/public_html`

The parameters `vhost_params` and `vhost_locations` are used to pass data to the according defined type of the [jfryman/nginx](https://forge.puppetlabs.com/jfryman/nginx)
Puppet module. Have a look at this modules documentation to get to know more about how it works.

### SSL Configuration

Together with defining an `ssl_cert` SSL gets activated on the vhost. It uses modern SSL ciphers, disables old SSL versions and
adds a HSTS header.

To deliver an SSL certificate the `uhosting::certificates` hash can be filled. This is a small helper
to create the needed files ready to be consumed by Nginx. Filling the hash does not automatically add
the settings to the vhost, settings `ssl_cert` and `ssl_key` is still needed. Files are saved under:

* certificate: `/etc/ssl/certs/${name}.pem`
* key: `/etc/ssl/private/${name}.pem"`

Example:

```
uhosting::certificates:
  mysite_ch:
    certificate: |
      -----BEGIN CERTIFICATE-----
      [...]
      -----END CERTIFICATE-----
    key: |
      -----BEGIN PRIVATE KEY-----
      [...]
      -----END PRIVATE KEY-----
```
If you have to add a certificate chain just put the certificates after each other, make sure the actual server certificate is the last one, nginx will fail otherwise.

### Environment Variables

Environment variables are set in the uWSGI configuration and as shell variables for the particular vhost/site user. By default
the following variables are set:

* **SITENAME**
* **STACKTYPE**
* **DB_NAME**
* **DB_USER**
* **DB_PASSWORD**
* **DB_HOST**

Adding new variables can be done using the `env_vars` (hash) parameter of the site.

### Redirects

The hash `uhosting::redirects` can contain a hash of domain redirects. Example (hiera):

```
uhosting::redirects:
  mydestination.ch:
    - 'alternativedomain1.com'
    - 'alternativedomain2.com'
    - 'alternativedomain3.com'
    - 'alternativedomain4.com'
```

These redirects are written into `/etc/nginx/redirects.conf` which gets included into the
Nginx configuration. A redirect is done using 301 redirects directly in Nginx.

### DNS Server

This module supports Knot as a DNS server and brings some helpers for using it:

* **uhosting::dns_zones**: Hash of DNS zones
* **uhosting::dns_zone_defaults**: Passed directly to [Knot](https://github.com/tobru/puppet-knot) Puppet module
* **uhosting::dns_zone_keys**: Passed directly to [Knot](https://github.com/tobru/puppet-knot) Puppet module
* **uhosting::dns_zone_remotes**: Passed directly to [Knot](https://github.com/tobru/puppet-knot) Puppet module

## App Profiles

App profiles are used to quickly configure an app environment. It creates the vhost,
app specific locations in the vhost, the app worker (uWSGI or PHP FPM) and the best settings
for the app.

An app profile is located under `manifests/app` and has the following parameters:
* **app_settings**: Hash of different settings to influence the app configuration
  from hiera. This is application specific and documented inside the defined type.


All other parameters are coming from `site.pp` and are for internal use:
* **ssl**
* **vassals_dir**
* **vhost_defaults**
* **webroot**

To create a new app profile:

1. Fork this repository
1. Add new defined type under `app/<appname>.pp`, take `owncloud.pp` as a boilerplate
1. Create pull request

## Stack Types

The following stack types are known:

* **static**: Serves static files from the public_html folder
* **uwsgi**: Uses uWSGI as app worker, supports many languages
* **phpfpm**: Uses PHP-FPM to serve PHP applications (use as last resort if uWSGI with PHP doesn't work)
* **unicorn**: Controls unicorn via supervisord, unicorn has to be installed by bundler / Gemfile manually. Set `unicorn_conf` to an absolute path for manual config


### Stack type `static`

Just serves static files from `/var/www/<sitename>/public_html`

### Stack type `uwsgi`

Using this stack type asks for another parameter: `uwsgi_plugin`. Can be one of `php`, `ruby` or `python`.
This stack type also allows adding more uWSGI parameters to the vassal configuration using
the `uwsgi_params` (hash) site parameter.

#### `php`

Configures uWSGI for the PHP plugin and points Nginx to use that one.

#### `ruby`

Using this plugin it is necessary to add the `rack` parameter which must
point to a `.ru` file. It then uses this file to start the Ruby application and point
Nginx to this application.

#### `python`

To successfully start a Python app, uWSGI needs to know what to do. F.e. one
can use the `uwsgi_param` `wsgi-file` to point to a WSGI file.

When using this plugin, it's possible to install PIP into a virtualenv: Just
define the PIP packages on the `pip_packages` site parameter (hash). When specifying
PIP packages, a virtualenv is automatically created under `${homedir}/virtualenv`.

#### Maintenance

The site user account can run the following command:

* **urestart**: Tells uwsgi to restart this site's worker process.


### Stack type `phpfpm`

This type configures a PHP-FPM master process (dynamic pools)
for this site which is managed by SupervisorD.

Settings can be influenced by the following site parameters:

* **php_flags**
* **php_values**
* **php_admin_flags**
* **php_admin_values**

#### Maintenance

The site user account can run the following commands:

* **ustop**: Tells supervisord to stop the php-fpm process of this site. This is not
  persistent: A restart of supervisord will restart the php-fpm process.
* **ustart**: Tells supervisord to start the previously stopped php-fpm process of this site.
* **urestart**: Tells supervisord to restart the php-fpm process of this site.


### Stack type `nodejs`

This type configures a NodeJS instance managed by SupervisorD.

By default, nginx is set up such that all requests are proxied directly to this instance.

To use the NodeJS stack type, the following dependencies must be fulfilled:
* [willdurand/nodejs](https://forge.puppetlabs.com/willdurand/nodejs)
* [maestrodev/wget](https://forge.puppetlabs.com/maestrodev/wget) (required by willdurand/nodejs)

Parameters:

* **nodejs_version**: NodeJS version for this vhost, format "v4.2.1", "stable" or
  "latest" (the latter two update NodeJS automatically and are thus not recommended for production).
  Default is "stable".
* **nodejs_packages**: Array of Node packages to be installed on this vhost. Either [package]
  or [package]@[version]. The packages will be installed into the `[vhost]/node_modules`
  directory.
* **nodejs_port**: Port number for nginx to connect to. The NodeJS application must listen
  on this port on 127.0.0.1. Required, unless **nodejs_disable_vhost** is true.
* **nodejs_disable_vhost**: Run NodeJS without nginx vhost. This is useful for NodeJS
  applications that only have a back-end function and are not directly accessed by clients.
  Default is false.

#### Maintenance

The site user account can run the following commands:

* **ustop**: Tells supervisord to stop the NodeJS process of this site. This is not
  persistent: A restart of supervisord will restart the NodeJS process.
* **ustart**: Tells supervisord to start the previously stopped NodeJS process of this site.
* **urestart**: Tells supervisord to restart the NodeJS process of this site.


## Vagrant specials

The module contains a specific `Vagrantfile` to have a local testing environment
* for this module and
* for testing web applications easily

It depends on the following Vagrant plugins:

* [landrush](https://github.com/phinze/landrush): local DNS
* [librarian-puppet](https://github.com/mhahn/vagrant-librarian-puppet): Puppetfile handling

The hiera data is saved under `vagrant/hieradata.yaml`, which is also parsed by Vagrant
and the `server_names` feeded into landrush for easy site access. For every site defined,
it creates an entry named `<server_name>.vagrant.dev`. If you've configured your local
resolver correctly (f.e. dnsmasq) you're able to immediately access a newly created site
in your local browser.

Running Puppet again in the VM is done by callling the script `/vagrant/vagrant/runpuppet.sh`
inside the VM as root.

## Examples

Here are some Hiera examples:

### Example 1: Plain static vhost

```
uhosting::sites:
  mystatic_net:
    server_names:
      - 'mystatic.net'
    ssl_cert: '/etc/ssl/certs/mystatic.net.pem'
    ssl_key: '/etc/ssl/private/mystatic.net.key'
    ssl_rewrite_to_https: false
    stack_type: 'static'
```

### Example 2: App profile ownCloud

```
uhosting::sites:
  myowncloud:
    server_names:
      - 'mycloud.domain.net'
    app: 'owncloud'
    app_settings:
      version: 'v9.0.1'
    database: 'mariadb'
    db_password: 'really-secure-password'
```

### Example 3: Custom PHP configuration

```
uhosting::sites:
  mycustomphpapp_net:
    server_names:
      - 'phpapp.domain.net'
    stack_type: 'uwsgi'
    uwsgi_plugin: 'php'
    database: 'mariadb'
    db_password: 'really-secure-password'
    vhost_params:
      use_default_location: false
      www_root: '/var/www/mycustomphpapp_net/public_html/public'
    vhost_locations:
      root:
        location: '/'
        location_custom_cfg:
          try_files:
            - '$uri $uri/ /index.php?$query_string'
      php:
        location: '~ \.php$'
        include:
          - 'uwsgi_params'
        location_custom_cfg:
          uwsgi_modifier1: 14
          uwsgi_param: 'HTTPS on'
          uwsgi_pass: 'unix:/var/lib/uhosting/mycustomphpapp_net.socket'
    uwsgi_params:
      php-docroot: ''
      chdir: '/var/www/mycustomphpapp_net/public_html'
```

### Example 4: Custom Python application

```
uhosting::sites:
  python_app:
    server_names:
      - 'pythonapp.domain.tld'
    server_names_extra:
      - '*.pythonapp.domain.tld'
    stack_type: 'uwsgi'
    uwsgi_plugin: 'python'
    database: 'mariadb'
    db_password: 'really-secure-password'
    uwsgi_params:
      virtualenv: '/var/www/python_app/virtualenv'
      wsgi-file: '/var/www/python_app/wsgiapp.py'
    pip_packages:
      setuptools: {}
    webroot: '/var/www/python_app/public_html'
```

### Example 5: Custom Ruby application

```
uhosting::sites:
  ruby_app:
    server_names:
      - 'rubyapp.domain.tld'
    stack_type: 'uwsgi'
    uwsgi_plugin: 'ruby'
    database: 'mariadb'
    db_password: 'really-secure-password'
    rack: '/var/www/ruby_app/app/config.ru'
    webroot: '/var/www/ruby_app/app/public'
    env_vars:
      RAILS_ENV: 'production'
```

## Limitations

The module is only tested under Ubuntu 14.04 and will probably not run with other distributions.

## Known Issues

due to a dependency issues a initial 2nd puppet run or manual reload of nginx is needed for SSL to work

## Development

1. Fork it (https://github.com/vshn/uhosting/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Not yet implemented features (Help appreciated)

* Site removal (needs testing)
* PHP extension handling
* Redis
