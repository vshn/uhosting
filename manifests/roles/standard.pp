#
class uhosting::roles::standard {

  # Webserver
  include uhosting::profiles::nginx

  # Web application server
  include uhosting::profiles::uwsgi
  # include uhosting::language::php
  # include uhosting::language::python
  # include uhosting::language::ruby
  # include uhosting::language::go

  # Database server
  include uhosting::profiles::mariadb
  include uhosting::profiles::postgresql

  # DNS server
  include uhosting::profiles::knot

  # maybe: redis, solr?
  #include uhosting::profiles::webhookd

}
