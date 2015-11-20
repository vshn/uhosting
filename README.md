# WARNING

**This module is its really early stages and not yet very well tested or even finished**

Use at your own risk!

#### Table of Contents

1. [Overview](#overview)
1. [Module Description - What the module does and why it is useful](#module-description)
1. [Setup - The basics of getting started with uhosting](#setup)
    * [What uhosting affects](#what-uhosting-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with uhosting](#beginning-with-uhosting)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)

## Overview

Easy webhosting with a collection of profiles and easy resource creation.

## Module Description

This module has a lot of opinionated content. It reflects my current idea of a simple,
multi language hosting configuration.

It serves to main purposes:

* A local Vagrant machine to try out webapplications in the same environment
  as it could later run on
* A configuration mechanism to define websites, including application specific
  configuration, database management, and so on.

Based on the following key technologies:

* Nginx
* uWSGI
* MariaDB
* PostgreSQL
* Knot DNS
* Ubuntu 14.04 Server

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

Just include the `uhosting` class and define a bsic site in the `uhosting::sites` hash:

```YAML
uhosting::sites:
  mysite_com:
    server_names:
      - 'mysite.com'
    stack_type: 'static'
```

This example sets up a Nginx with a virtual server for mysite.com.

## Usage

Including the `uhosting` class won't do anything but validating the `uhosting::sites` hash and
calling the `resources::site` type using some stdlib-fu.
The real magic happens in the `resources::site` class where it uses the parameters found in
`uhosting::sites` to create the needed configuration.

All components are installed only when needed. So when there is no site defined using a 
database, it won't be installed. As soon as a site uses a database, the specific database
is installed and configured. This applies also to Nginx, uWSGI, the language stack, Knot etc.

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

## Reference

### Parameters for `uhosting::sites`

* ! **_key** (string): The key of the hash defines the identifier of the site
  and will be used to f.e. create a system user. Do not change it once it is set!
* ! **server_names** (array of strings): Virtual domain names. `www.` will be added automatically
* ! **stack_type** (string): Type of the hosting stack. Possible values: `static` and `uwsgi`
  If the stack type is `uwsgi`, the parameter `uwsgi_plugin` needs to be configured too.
* **vhost_params** (hash): Parameters for the `nginx::resource::vhost` type. Can be used to add
  additional settings or overwrite the defaults.
* **vhost_locations** (hash): Parameters for the `nginx::resource::location` type. Passed to `create_resources`.
* **uid** (integer): uid of the siteuser which will be created. If unset it choses the next free.
* **uwsgi_plugin** (string): uWSGI plugin to load for this site.
* **uwsgi_params** (hash): Can be used to define additional uWSGI vassal settings or overwrite
  the default onces.
* **ssl_cert** (path): Path to the ssl certificate on the server. This activates SSL on the vhost.
* **ssl_key** (path): Path to the ssl key on the server.
* **database** (string): Type of database to manage for this site.
* **db_password** (string): Plain text password to set for this site.
* **db_user**: If not set, the db user will be the same as the key.
* **db_name**: If not set, the db name will be the same as the key.

! mandatory

### Default settings

* site user home directory: `/var/www/${name}`
* website root: `/var/www/${name}/public_html`

## Limitations

The module is only tested under Ubuntu 14.04 and will probably not run with other distributions.

## Not yet documented features

* Redirects
* DNS zones

## Not yet implemented features

* PostgreSQL database handling
* Site removal
* PHP extension handling
* Redis
