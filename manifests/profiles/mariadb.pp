#
class uhosting::profiles::mariadb (
  $root_password,
) {

  ## Database Server Maria DB (fork of MySQL)
  $mariadb_server_options = {
    'mysqld'                 => {
      'bind-address'         => '127.0.0.1',
      'skip_name_resolve'    => '1',
      'max_allowed_packet'   => 36700160,
      'max_connections'      => 600,
      'slow_query_log'       => 0,
      'character_set_server' => 'utf8',
      'collation_server'     => 'utf8_bin',
    }
  }

  # Define APT source if not already there
  ::apt::source { 'mariadb':
    comment     => 'official MariaDB repo',
    location    => 'http://mariadb.kisiek.net/repo/10.0/ubuntu',
    release     => $::lsbdistcodename,
    repos       => 'main',
    key      => {
      'id' => '199369E5404BD5FC7D2FE43BCBCB082A1BB943DB',
      'server' => 'hkp://keyserver.ubuntu.com:80',
    },
    include  => {
      'src' => false,
      'deb' => true,
    }
  }

  # Install MariaDB client if not already there
  class { '::mysql::client':
    package_name => 'mariadb-client',
    require      => Apt::Source['mariadb'],
  }

  # Install MariaDB server
  class { '::mysql::server':
    root_password    => $root_password,
    includedir       => undef,
    package_name     => 'mariadb-server',
    override_options => $mariadb_server_options,
    require          => Apt::Source['mariadb'],
  } ->
  # Deletes default MySQL accounts
  class { '::mysql::server::account_security': }

  # install MySQL Tuner script. Source:
  # https://github.com/major/MySQLTuner-perl
  class { '::mysql::server::mysqltuner':
    version => 'v1.4.0',
  }

  ### Resources
  ## Get sites from hiera
  $sitehash = hiera('uhosting::sites')
  $sites = keys($sitehash)

  ## Create the databases
  ::uhosting::resources::mariadb { $sites:
    data => $sitehash,
  }

  ## Firewall settings
  #firewall {
  #  '020 open MariaDB IPv4':
  #    dport  => 3306,
  #    proto  => 'tcp',
  #    action => 'accept';
  #  '020 open MariaDB IPv6':
  #    dport    => 3306,
  #    proto    => 'tcp',
  #    action   => 'accept',
  #    provider => 'ip6tables';
  #}

}
