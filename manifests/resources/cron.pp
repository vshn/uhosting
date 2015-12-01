# == Class: uhosting::resources::cron
#
# Creates a cron job, enforces the site user
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::resources::cron (
  $data,
  $user,
) {

  $_cronjob = { "$name" => $data[$name] }
  $_defaults = { user => $user }

  if $data[$name]['user'] {
    fail("YOU ARE NOT ALLOWED TO SET THE CRON USER. RESOURCE ${name}")
  } else {
    create_resources('cron',$_cronjob,$_defaults)
  }

}
