#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with uhosting](#setup)
    * [What uhosting affects](#what-uhosting-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with uhosting](#beginning-with-uhosting)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

A one-maybe-two sentence summary of what the module does/what problem it solves. This is your 30 second elevator pitch for your module. Consider including OS/Puppet version it works with.       

## Module Description

If applicable, this section should have a brief description of the technology the module integrates with and what that integration enables. This section should answer the questions: "What does this module *do*?" and "Why would I use it?"

If your module has a range of functionality (installation, configuration, management, etc.) this is the time to mention it.

## Setup

### What uhosting affects

* A list of files, packages, services, or operations that the module will alter, impact, or execute on the system it's installed on.
* This is a great place to stick any warnings.
* Can be in list or paragraph form. 

### Setup Requirements **OPTIONAL**

If your module requires anything extra before setting up (pluginsync enabled, etc.), mention it here. 

### Beginning with uhosting

The very basic steps needed for a user to get the module up and running. 

If your most recent release breaks compatibility or requires particular steps for upgrading, you may wish to include an additional section here: Upgrading (For an example, see http://forge.puppetlabs.com/puppetlabs/firewall).

## Usage

Put the classes, types, and resources for customizing, configuring, and doing the fancy stuff with your module here. 

## Reference

Here, list the classes, types, providers, facts, etc contained in your module. This section should include all of the under-the-hood workings of your module so people know what the module is touching on their system but don't need to mess with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them know what the ground rules for contributing are.

## Release Notes/Contributors/Etc **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You may also add any additional sections you feel are necessary or important to include here. Please use the `## ` header. 

## Temporary Examples

```
---
classes:
  - uhosting::profiles::nginx
  - uhosting::profiles::uwsgi
  - uhosting::profiles::mariadb
  - uhosting::profiles::postgresql
  - uhosting::profiles::knot

uhosting::profiles::mariadb::root_password: 'Passw0rd'
uhosting::sites:
  tobru_ch:
    server_names:
      - 'tobru.ch'
    stacktype: 'static'
    database: false
    ssl_type: 'selfsigned'
  foti_broesme_li:
    server_names:
      - 'broesme.li'
      - 'foti.broesme.li'
    stacktype: 'php'
    database: false
    ssl_type: 'selfsigned'
uhosting::dns_zones:
  - 'tobru.ch'
```

# Testfiles

/var/www/rubysite_ch/public_html/ruby.ru
```
class App

  def call(environ)
    [200, {'Content-Type' => 'text/html'}, ['Hello']]
  end

end

run App.new
```

/var/www/pythonsite_ch/public_html/foobar.py
```
def application(env, start_response):
    start_response('200 OK', [('Content-Type','text/html')])
    return [b"Hello World"]
```

/var/www/phpsite_ch/public_html/index.php
```
<?php phpinfo();
```
