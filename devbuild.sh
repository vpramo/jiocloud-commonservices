set -xe
BUILD_TAG=test_commonservices #Change this as required
export KEY_NAME=vpramo_key # Key name , will parametrize
export env_file="/home/vpramo/vpramo_staging_openrc" #will parametrize
export dns_server=10.0.0.2
export env_http_proxy=http://10.0.0.2:3128/
export env_https_proxy=http://10.0.0.2:3128/
export git_protocol=https
export BUILD_NUMBER=$BUILD_TAG
export env=commonservices
export cloud_provider=commonservices
export layout=commonservices
./build_scripts/deploy.sh
