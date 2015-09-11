#!/bin/bash -xe
export puppet_modules_source_repo='https://github.com/vpramo/puppet-commonservices'
cat <<EOF >userdata.txt
#!/bin/bash
date
set -x
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export layout="${layout}"
release="\$(lsb_release -cs)"
sudo mkdir -p /etc/facter/facts.d
if [ -n "${git_protocol}" ]; then
  export git_protocol="${git_protocol}"
fi
export no_proxy="127.0.0.1"
echo no_proxy="'127.0.0.1'" >> /etc/environment
if [ -n "${env_http_proxy}" ]
then
  export http_proxy=${env_http_proxy}
  echo http_proxy="'${env_http_proxy}'" >> /etc/environment
fi
if [ -n "${env_https_proxy}" ]
then
  export https_proxy=${env_https_proxy}
  echo https_proxy="'${env_https_proxy}'" >> /etc/environment
fi
if [ -n "${dns_override}" ]; then
  echo 'nameserver ${dns_override}' > /etc/resolv.conf
fi
wget -O puppet.deb -t 5 -T 30 http://apt.puppetlabs.com/puppetlabs-release-\${release}.deb
if [ "${env}" == "at" ]
then
  jiocloud_repo_deb_url=http://jiocloud.rustedhalo.com/ubuntu/jiocloud-apt-\${release}-testing.deb
else
  jiocloud_repo_deb_url=http://jiocloud.rustedhalo.com/ubuntu/jiocloud-apt-\${release}.deb
fi

n=0
while [ \$n -le 5 ]
do
  apt-get update && apt-get install -y puppet software-properties-common && break
  n=\$((\$n+1))
  sleep 5
done

if [ -n "${puppet_modules_source_repo}" ]; then
  apt-get install -y git
  git clone ${puppet_modules_source_repo} /tmp/commonservice
  if [ -n "${puppet_modules_source_branch}" ]; then
    pushd /tmp/commonservice
    git checkout ${puppet_modules_source_branch}
    popd
  fi
  if [ -n "${pull_request_id}" ]; then
    pushd /tmp/commonservice
    git fetch origin pull/${pull_request_id}/head:test_${pull_request_id}
    git config user.email "testuser@localhost.com"
    git config user.name "Test User"
    git merge -m 'Merging Pull Request' test_${pull_request_id}
    popd
  fi
  time gem install librarian-puppet-simple --no-ri --no-rdoc;
  mkdir -p /etc/puppet/manifests.overrides
  cp /tmp/commonservice/site.pp /etc/puppet/manifests.overrides/
  mkdir -p /etc/puppet/hiera.overrides
  sed  -i "s/  :datadir: \/etc\/puppet\/hiera\/data/  :datadir: \/etc\/puppet\/hiera.overrides\/data/" /tmp/commonservice/hiera/hiera.yaml
  cp /tmp/commonservice/hiera/hiera.yaml /etc/puppet
  cp -Rvf /tmp/commonservice/hiera/data /etc/puppet/hiera.overrides
  mkdir -p /etc/puppet/modules.overrides/commonservice
  cp -Rvf /tmp/commonservice/* /etc/puppet/modules.overrides/commonservice/
  if [ -n "${module_git_cache}" ]
  then
    cd /etc/puppet/modules.overrides
    wget -O cache.tar.gz "${module_git_cache}"
    tar xvzf cache.tar.gz
    time librarian-puppet update --puppetfile=/tmp/commonservice/Puppetfile --path=/etc/puppet/modules.overrides
  else
    time librarian-puppet install --puppetfile=/tmp/commonservice/Puppetfile --path=/etc/puppet/modules.overrides
  fi
  cat <<INISETTING | puppet apply --config_version='echo settings'
  ini_setting { basemodulepath: path => "/etc/puppet/puppet.conf", section => main, setting => modulepath, value => "/etc/puppet/modules.overrides:/etc/puppet/modules" }
  ini_setting { default_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => manifest, value => "/etc/puppet/manifests.overrides/site.pp" }
  ini_setting { disable_per_environment_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => disable_per_environment_manifest, value => "true" }
INISETTING
else
  puppet apply --config_version='echo settings' -e "ini_setting { default_manifest: path => \"/etc/puppet/puppet.conf\", section => main, setting => default_manifest, value => \"/etc/puppet/manifests/site.pp\" }"
fi

echo 'current_version='${BUILD_NUMBER} > /etc/facter/facts.d/current_version.txt
echo 'env='${env} > /etc/facter/facts.d/env.txt
echo 'cloud_provider='${cloud_provider} > /etc/facter/facts.d/cloud_provider.txt


##
# Workaround to add the swap partition for baremetal systems, as even though
# cloudinit is creating the swap partition, its not added to the fstab and not
# enabled.
##
if [ -e /dev/disk/by-label/swap1 ] && [ `grep -cP '^LABEL=swap1[\s\t]+' /etc/fstab` -eq 0 ]; then
  echo 'LABEL=swap1 none swap sw 0 1' >> /etc/fstab
  swapon -a
fi

while true
do
  # first install all packages to make the build as fast as possible
  puppet apply --detailed-exitcodes \`puppet config print manifest\`
  ret_code_jio=\$?
  if [[ \$ret_code_jio = 1 || \$ret_code_jio = 4 || \$ret_code_jio = 6 ]]
  then
    echo "Puppet failed. Will retry in 5 seconds"
    sleep 5
  else
    break
  fi
done
date
EOF
