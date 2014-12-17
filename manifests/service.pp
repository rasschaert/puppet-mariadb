# Class: mariadb::service
#
#
class mariadb::service {
  if $::mariadb::galera {
    service { 'mysql':
      enable  => false,
    }
  } else {
    service { 'mysql':
      ensure  => running,
      enable  => true,
      require => File['/etc/my.cnf'],
    }
  }
}
