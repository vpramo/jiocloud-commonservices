#!/bin/bash -xe

. $(dirname $0)/common.sh


. $(dirname $0)/make_userdata.sh

  time python -m jiocloud.apply_resources apply ${EXTRA_APPLY_RESOURCES_OPTS} --key_name=${KEY_NAME:-combo} --project_tag=${project_tag} ${mappings_arg} environment/${layout}.yaml userdata.txt
