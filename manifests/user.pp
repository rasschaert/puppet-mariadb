# Define: mariadb::user
# Parameters:
# arguments
#
define mariadb::user (
  $pass  = '',
  $host  = '%',
  $db    = '*',
  $table = '*',
  $privs = 'ALL',
) {
  $cmd = "mysql -uroot -p${::mariadb::root_password} -e \"GRANT ${privs} ON \
          ${db}.${table} TO\'${name}'@'${host}' IDENTIFIED BY '${pass}';\""

  $unless = "mysql --batch --skip-column-names -uroot -ptoor -e \"SELECT \
             User, Host FROM mysql.user;\" | egrep -q '^sst\\s+%\$'"

  exec { "Add MariaDB user ${name}":
    command => $cmd,
    unless  => $unless,
    path    => '/bin',
    require => Exec['Set MariaDB root password'],
    notify  => Exec['flush privileges'],
  }
}
