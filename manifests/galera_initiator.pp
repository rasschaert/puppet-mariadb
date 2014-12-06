# Class: mariadb::galera
#
#
class mariadb::galera_initiator {
  file { '/usr/local/sbin/galera-check.sh':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/mariadb/galera-check.sh',
  }

  snmp::server::extend { 'galeraStatus':
    command => '/usr/local/sbin/galera-check.sh status',
  }

  snmp::server::extend { 'galeraSeqno':
    command => '/usr/local/sbin/galera-check.sh seqno',
  }

  file { '/usr/local/sbin/galera-initiator.py':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/mariadb/galera-initiator.py',
    require =>  [
                  Snmp::Server::Extend['galeraStatus'],
                  Class['snmp::client'],
                  Class['snmp::server'],
                ],
  }

  file { '/etc/systemd/system/galera-initiator.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/mariadb/galera-initiator.service',
    require => File['/usr/local/sbin/galera-initiator.py'],
  }

  service { 'galera-initiator':
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/galera-initiator.service'],
  }
}
