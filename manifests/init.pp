# Class: mariadb
#
#
class mariadb (
  $galera = false,
) {

  include mariadb::install
  include mariadb::config
  include mariadb::service

  Class['mariadb::install'] ->
  Class['mariadb::config']  ->
  Class['mariadb::service']

  if galera {
    include mariadb::galera
  }
}
