# Class: mariadb::galera
#
#
class mariadb::galera (
  $cluster_members = [],
  $interface       = 'eth0',
) {

  $node_address = inline_template("<%= scope.lookupvar('::ipaddress_${interface}') -%>")

  file { '/etc/my.cnf.d/galera.cnf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[mysql],
    content => template('mariadb/galera.cnf.erb'),
    require => File['/etc/my.cnf.d'],
  }

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
  file { '/usr/local/sbin/galera-start.py':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/mariadb/galera-start.py',
    require =>  [
                  Snmp::Server::Extend['galeraStatus'],
                  Class['snmp::client'],
                  Class['snmp::server'],
                ],
  }
  file { '/etc/systemd/system/galera-start.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/mariadb/galera-start.service',
    require => File['/usr/local/sbin/galera-start.py'],
  }
  # service { 'galera-start':
  #   ensure  => running,
  #   enable  => true,
  #   require => File['/etc/systemd/system/galera-start.service'],
  # }
}
