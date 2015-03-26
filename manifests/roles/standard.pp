#
class uhosting::roles::standard {

  # Webserver
  include uhosting::profiles::nginx

  # Web application server
  include uhosting::profiles::uwsgi

  # Database server
  include uhosting::profiles::mariadb
  include uhosting::profiles::postgresql

  # DNS server
  include uhosting::profiles::knot

  # maybe: redis, solr?

}
