Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ], logoutput => true }

node /^commonsrv/ {
  include commonservice::base
  include commonservice::rsyslog
}
