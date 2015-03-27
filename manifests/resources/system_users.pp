#
class uhosting::resources::system_users inherits ::uhosting {

  $site_names = keys($uhosting::sites)

  user { $site_names:
    home => $name
  }

}
