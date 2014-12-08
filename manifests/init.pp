# Class: mariadb
#
#
class mariadb (
  $root_password   = '',
  $galera          = false,
  $sst_user        = 'sst',
  $sst_password    = '',
  $cluster_members = [],
  $node_address    = '127.0.0.1',
) {

  contain mariadb::install
  contain mariadb::config
  contain mariadb::service
  contain mariadb::authentication

  Class['mariadb::install'] ->
  Class['mariadb::config']  ->
  Class['mariadb::service'] ->
  Class['mariadb::authentication']

  if galera {
    contain mariadb::galera_initiator
    Class['mariadb::galera_initiator'] ->
    Class['mariadb::authentication']
  }
}
