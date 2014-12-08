# Class: mariadb::service
#
#
class mariadb::service {
  if $::mariadb::galera {
    service { 'mysql':
      enable  => false,
    }
    firewall { '100 allow galera':
      chain  => 'INPUT',
      state  => ['NEW'],
      dport  => '4567',
      proto  => 'tcp',
      action => 'accept',
    }
    firewall { '100 allow galera sst':
      chain  => 'INPUT',
      state  => ['NEW'],
      dport  => '4444',
      proto  => 'tcp',
      action => 'accept',
    }
    firewall { '100 allow galera ist':
      chain  => 'INPUT',
      state  => ['NEW'],
      dport  => '4568',
      proto  => 'tcp',
      action => 'accept',
    }
  } else {
    service { 'mysql':
      ensure  => running,
      enable  => true,
      require => File['/etc/my.cnf'],
    }
  }
  firewall { '100 allow mariadb':
    chain  => 'INPUT',
    state  => ['NEW'],
    dport  => '3306',
    proto  => 'tcp',
    action => 'accept',
  }
}
