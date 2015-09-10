#!/bin/bash

if [ -z "${env}" ]
then
    echo '$env must be defined'
    exit 1
fi

#
# default layout to full if it is not set
#
if [ -z "${layout}" ]; then
  layout=full
fi

if [ -z "${cloud_provider}" ]; then
  # defaulting it to env for backwards compatibility
  cloud_provider=$env
fi

# Load credentials (openrc style)
if set -o | grep xtrace | grep on; then
  xtrace_was_on=1
  set +x
fi
. ${env_file:-/var/lib/jenkins/cloud.${cloud_provider}.env}
if [ -n "${xtrace_was_on}" ]; then
  set -x
fi

##
# Load map from generic image, flavor and network names to
# cloud specific ids
#
# overcast use ini file for mapping.
##
if [ $provisioner == 'overcast' ]; then
  mapping_file="environment/${cloud_provider}.map.ini"
else
  mapping_file="environment/${cloud_provider}.map.yaml"
fi

if [ -n "${mapping}" ]
then
	mappings_arg="--mappings=${mapping}"
elif [ -e $mapping_file ]
then
	mappings_arg="--mappings=${mapping_file}"
else
	mappings_arg=""
fi

export project_tag=${project_tag:-test${BUILD_NUMBER}}

if ! [ -e venv ]
then
    virtualenv venv
    . venv/bin/activate
    pip install -U pip

    # This speeds the whole process up *a lot*
    pip install pip-accel
    if [ -n "${python_jiocloud_source_repo}" ]; then
      if [ -z "${python_jiocloud_source_branch}" ]; then
        python_jiocloud_source_branch='master'
      fi
      pip-accel install -e "${python_jiocloud_source_repo}@${python_jiocloud_source_branch}#egg=jiocloud"
    else
      pip-accel install -e git+https://github.com/JioCloud/python-jiocloud#egg=jiocloud
    fi

    if [ $provisioner == 'overcast' ]; then
      if [ -n "${overcast_source_repo}" ]; then
        if [ -z "${overcast_source_branch}" ]; then
          overcast_source_branch='master'
        fi
        pip-accel install -e "${overcast_source_repo}@${overcast_source_branch}#egg=overcast"
      else
        pip-accel install -e git+https://github.com/overcastde/python-overcast#egg=overcast
      fi
    fi
    deactivate
fi

. venv/bin/activate

# this is here to allow a user to override the command used for
# the timeout function just incase it happens to be gtimeout
timeout=${timeout_command:-timeout}
