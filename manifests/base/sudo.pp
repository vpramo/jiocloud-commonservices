# Define commonservice::base::sudo
#
# == Purpose
# Call commonservice::base::sudo::conf with appropriate params

define commonservice::base::sudo (
  $active_users     = [],
  $users            = [],
  $commands_allowed = [],
) {

  ## Make an intersection of active users and sudo users,
  ##  so that sudo_users are always a subset of active_users

  $sudo_users = intersection($active_users,$users)

  ::commonservice::base::sudo::conf { $sudo_users:
    commands_allowed => $commands_allowed,
  }
}
