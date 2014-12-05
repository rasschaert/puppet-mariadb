# Class: mariadb
#
#
class mariadb (
  $galera = false,
) {
  yumrepo { 'MariaDB-10.0':
    # MariaDB issue MDEV-7235
    # baseurl  => 'http://yum.mariadb.org/10.0/centos7-amd64',
    baseurl  => 'http://yum.mariadb.org/10.0/centos6-amd64',
    descr    => 'MariaDB repository',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
  }

  if $galera {
    # From MariaDB 10.1.1 on, we can use MariaDB-server package in both cases
    # https://blog.mariadb.org/mariadb-10-1-1-galera-support/
    $server_package = 'MariaDB-Galera-server'
    service { 'mysql':
      enable  => false,
    }
    include mariadb::galera
  } else {
    $server_package = 'MariaDB-server'
    service { 'mysql':
      ensure  => running,
      enable  => true,
      require => File['/etc/my.cnf'],
    }
  }

  package { $server_package:
    ensure  => installed,
    require => Yumrepo['MariaDB-10.0'],
  }

  file { '/etc/my.cnf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[mysql],
    content => template('mariadb/my.cnf.erb'),
    require => Package[$server_package],
  }

  # Already created by package, but it's nice to have it as a puppet resource
  file { '/etc/my.cnf.d':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # The MariaDB server package installs unwanted config files in /etc/my.cnf.d
  file { '/etc/my.cnf.d/server.cnf':
    ensure  => absent,
    notify  => Service[mysql],
    require => Package[$server_package],
  }
  file {'/etc/my.cnf.d/tokudb.cnf':
    ensure  => absent,
    notify  => Service[mysql],
    require => Package[$server_package],
  }

  ###############
  # YAK SHAVING #
  ###############
  # If any of the  MariaDB 5.5 packages that come with CentOS7 are already
  # installed, yum will refuse to install the MariaDB 10.0 packages.
  # The Puppetlabs CentOS 7 Vagrant box comes with mariadb-libs-5.5 installed.
  if ($::osfamily == 'RedHat' and $::operatingsystemmajrelease == 7) {
    # Thankfully the counterpart package for MariaDB 10 has a different name
    # or it would have been a lot harder to remove this package idempotently
    package { 'mariadb-libs':
      ensure            => absent,
      # The yum provider can complain that these libs might be needed by other
      # packages like postfix. Yum makes a good point, but we're putting those
      # libs back later on when the newer MariaDB is installed
      provider          => rpm,
      uninstall_options => '--nodeps',
      before            => [
                              Package[$server_package],
                            ],
    }
    augeas { 'exlude-mariadb-5.5':
      context => '/files/etc/yum.repos.d/CentOS-Base.repo',
      changes => 'set base/exclude mariadb-*',
    }
    Augeas['exlude-mariadb-5.5'] -> Package <| |>
  }
}
