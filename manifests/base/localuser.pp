## Define: commonservice::base::localuser

define commonservice::base::localuser(
  $realname,
  $sshkeys = '',
  $password = '*',
  $shell = '/bin/bash'
) {
  group { $title:
    ensure => present,
  }

  user { $title:
    ensure     => present,
    comment    => $realname,
    gid        => $title,
    home       => "/home/${title}",
    managehome => true,
    password   => $password,
    membership => 'minimum',
    require    => Group[$title],
    shell      => $shell,
  }

  file { "${title}_sshdir":
    ensure  => directory,
    name    => "/home/${title}/.ssh",
    owner   => $title,
    group   => $title,
    mode    => '0700',
    require => User[$title],
  }

  file { "${title}_keys":
    ensure  => present,
    content => $sshkeys,
    group   => $title,
    mode    => '0400',
    name    => "/home/${title}/.ssh/authorized_keys",
    owner   => $title,
    require => File["${title}_sshdir"],
  }
}
