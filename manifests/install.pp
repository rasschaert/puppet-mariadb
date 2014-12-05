# Class: mariadb::install
#
#
class mariadb::install {
  yumrepo { 'MariaDB-10.0':
    # MariaDB issue MDEV-7235
    # baseurl  => 'http://yum.mariadb.org/10.0/centos7-amd64',
    baseurl  => 'http://yum.mariadb.org/10.0/centos6-amd64',
    descr    => 'MariaDB repository',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
  }

  # From MariaDB 10.1.1 on, we can use MariaDB-server package in both cases
  # https://blog.mariadb.org/mariadb-10-1-1-galera-support/
  $server_package = $::mariadb::galera ? {
    true  => 'MariaDB-Galera-server',
    false => 'MariaDB-server',
  }
  package { $server_package:
    ensure  => installed,
    require => Yumrepo['MariaDB-10.0'],
  }

  #############################################################################
  #                                SHAVING YAK                                #
  #############################################################################
  # If any of the  MariaDB 5.5 packages that come with Enterprise Linux 7 are
  # already installed, yum will refuse to install the MariaDB 10.0 packages.
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
    augeas { 'exlude mariadb 5.5 from yum':
      context => '/files/etc/yum.repos.d/CentOS-Base.repo',
      changes =>  [
                    'set base/exclude mariadb-*',
                    'set updates/exclude mariadb-*'
                  ],
    }
    Augeas['exlude mariadb 5.5 from yum'] -> Package <| |>

  }
  #############################################################################
  #                                YAK SHAVED                                 #
  #############################################################################
}
