#
# Class commonservice::base
#
class commonservice::base(
  $proxy,
  $active_users,
  $local_users,
  $sudo_users,
  $repositories      = {},
  $proxy_enable      = false,
){
  ## Add Security message
  file { '/etc/issue':
    ensure        => file,
    owner         => root,
    group         => root,
    mode          => '0644',
    source        => "puppet:///modules/${module_name}/_etc_issue",
  }

  ## Add Proxy Settings
  create_resources(commonservice::base::proxy,$proxy)

  ## Account Settings
  create_resources('commonservice::base::instance',$local_users,{active_users => $active_users})

  ## Setup Sudoers
  class { 'sudo':
    purge => false,
    config_file_replace => false,
  }

  create_resources('commonservice::base::sudo', $sudo_users, {active_users => $active_users})

  ## Setup SSH Service
  class { 'ssh::server':
    options => {
      'PasswordAuthentication' => 'no',
      'PermitRootLogin'        => 'no',
      'Banner'                 => '/etc/issue.net',
      'Ciphers'                => 'aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com',
      'MACs'                   => 'hmac-sha1-etm@openssh.com,umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-ripemd160-etm@openssh.com,hmac-sha1-96-etm@openssh.com,hmac-sha1,umac-64@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-ripemd160'
    },
  }

  ## Add jiocloud Repos
  include ::apt
  if ($proxy_enable) {
    file { '/etc/apt/apt.conf.d/90proxy':
      content => "Acquire::Http::Proxy \"${proxy}\";",
      owner => 'root',
      group => 'root',
      mode  => '0644',
      tag   => 'package',
    }
  } else {
    file { '/etc/apt/apt.conf.d/90proxy':
      ensure => 'absent',
      tag   => 'package',
    }
  }
  create_resources(apt::source, $repositories, {'tag' => 'package'} )

}
