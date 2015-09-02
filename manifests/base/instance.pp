## Define commonservice::base::accounts::instance
## Purpose: to add active local users 

define commonservice::base::instance (
  $active_users,
  $realname = '',
  $sshkeys = '',
  $password = '*',
  $shell = '/bin/bash'
) {
  if member($active_users,$name) {
    commonservice::base::localuser { $name:
      realname => $realname,
      sshkeys => $sshkeys,
      password => $password,
      shell => $shell,
    }
  }
}

