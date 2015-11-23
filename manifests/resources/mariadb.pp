# == Define: uhosting::resources::mariadb
#
# Creates MariaDB user, database and grants
#
# === Parameters
#
# [*data*]
#   Hash of settings to be used for database creation
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::resources::mariadb (
  $data,
) {

  $sitedata = $data[$name]

  if $sitedata['database'] {
    # validate sitename:
    # * between 1 and 30 characters
    # * allowed characters: a-z, A-Z, 0-9, _, -
    validate_re($name,'^[a-zA-Z0-9_-]{1,30}$',"THE SITENAME '${name}' DOES NOT MATCH THE RULES (SEE DOCS)")

    # validate data in hiera
    if $sitedata['db_password'] {
      validate_string($sitedata['db_password'])
      $db_password = $sitedata['db_password']
    } else {
      fail("'db_password' FOR ${name} IS NOT CONFIGURED")
    }
    if $sitedata['db_user'] {
      $db_user = $sitedata['db_user']
      validate_re($db_user,'^[a-zA-Z0-9_-]{1,16}$',"THE DB NAME '${db_user}' DOES NOT MATCH THE RULES (SEE DOCS)")
    } else {
      $db_user = $name
      validate_re($db_user,'^[a-zA-Z0-9_-]{1,16}$',"THE DB NAME '${db_user}' DOES NOT MATCH THE RULES (SEE DOCS)")
    }
    if $sitedata['db_name'] {
      validate_string($sitedata['db_name'])
      $db_name = $sitedata['db_name']
    } else {
      $db_name = $name
    }
    if $sitedata['ensure'] {
      validate_re($sitedata['ensure'], '^present|absent$')
      $ensure = $sitedata['ensure']
    } else {
      $ensure = 'present'
    }
    $host    = '%'
    $grant   = ['ALL']
    $table   = "${db_name}.*"

    # Create DB
    mysql_database { $db_name:
      ensure   => $ensure,
      charset  => 'utf8',
      collate  => 'utf8_general_ci',
      provider => 'mysql',
    }

    # Create DB user
    mysql_user { "${db_user}@${host}":
      ensure        => $ensure,
      password_hash => mysql_password($db_password),
      provider      => 'mysql',
    }

    # Assign grants to user
    if $ensure == 'present' {
      mysql_grant { "${db_user}@${host}/${table}":
        privileges => $grant,
        provider   => 'mysql',
        user       => "${db_user}@${host}",
        table      => $table,
        require    => [Mysql_database[$db_name], Mysql_user["${db_user}@${host}"] ],
      }
    }
  }

}
