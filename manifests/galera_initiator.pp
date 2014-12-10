# Class: mariadb::galera
#
#
class mariadb::galera_initiator {

  ensure_packages(['python-pip','git'])

  snmp::server::extend { 'galeraStatus':
    command => '/usr/bin/galera_status',
  }

  snmp::server::extend { 'galeraSeqno':
    command => '/usr/bin/galera_seqno',
  }

  python::pip { 'GaleraInitiator' :
    ensure  => latest,
    url     => 'git+https://github.com/rasschaert/galera_initiator.git',
    require => [
                  Snmp::Server::Extend['galeraStatus'],
                  Snmp::Server::Extend['galeraSeqno'],
                  Class['snmp::client'],
                  Class['snmp::server'],
                ],
  }

  file { '/etc/systemd/system/galera-init.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/mariadb/galera-init.service',
    require => Python::Pip['GaleraInitiator'],
  }

  service { 'galera-init':
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/galera-init.service'],
  }
}
