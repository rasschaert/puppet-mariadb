# Class: mariadb::authentication
#
#
class mariadb::authentication {
  exec { 'Set MariaDB root password':
    command => "mysqladmin -u root password ${::mariadb::root_password}",
    path    => ['/usr/bin'],
    unless  => "mysqladmin -u root -p${::mariadb::root_password} status",
    require => Service['mysql'],
  }

  if $::mariadb::galera {
    mariadb::user { $::mariadb::sst_user:
      pass  => $::mariadb::sst_password,
      # privs => 'REPLICATION CLIENT, CREATE TABLESPACE, SUPER',
    }
  }

  exec { 'flush privileges':
    command     => "mysql -uroot -p${::mariadb::root_password} -e \
                    'FLUSH PRIVILEGES;'",
    path        => '/bin',
    refreshonly => true,
  }
}
