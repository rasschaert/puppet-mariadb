# Class: mariadb::config
#
#
class mariadb::config {
  file { '/etc/my.cnf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[mysql],
    content => template('mariadb/my.cnf.erb'),
  }

  # Already created by package, but it's nice to have it as a puppet resource
  file { '/etc/my.cnf.d':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/my.cnf.d/galera.cnf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[mysql],
    content => template('mariadb/galera.cnf.erb'),
    require => File['/etc/my.cnf.d'],
  }

  # The MariaDB server package installs unwanted config files in /etc/my.cnf.d
  file { '/etc/my.cnf.d/server.cnf':
    ensure => absent,
    notify => Service[mysql],
  }
  file {'/etc/my.cnf.d/tokudb.cnf':
    ensure => absent,
    notify => Service[mysql],
  }
}
