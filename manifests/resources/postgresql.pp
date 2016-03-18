# == Define: uhosting::resources::postgresql
#
# Creates postgresql user, database and grants
#
# === Parameters
#
# [*data*]
#   Hash of settings to be used for database creation
#
# === Authors
#
# Marco Fretz <marco.fretz@vshn.ch>
#
# === Copyright
#
# Copyright 2016 Marco Fretz, VSHN AG
#
define uhosting::resources::postgresql (
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
    postgresql::server::db { $db_name:
      user     => $db_user,
      password => postgresql_password($db_user, $db_password),
    }
  }

}
