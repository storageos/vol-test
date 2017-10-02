#!/bin/bash -e

BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Only source env if vars aren't set (by Jenkins) so it can be run manually
if [ -f $BASE/envfile.sh ]; then
  set -a
  . $BASE/envfile.sh
  set +a
fi

# While we only support Digital Ocean, default to it
IAAS=${IAAS:=do}

# Validate required params, the rest have defaults set in variables.tf
[ -z $TF_VAR_type ] && (>2& echo "TF_VAR_type must be set to benchmark or stress"; exit 1)
if [ -z $TF_VAR_build ]; then
  if [ -z $BUILD_TAG ]; then
    BUILD_TAG=$(whoami)
  fi
  export TF_VAR_build=$BUILD_TAG
fi

if ! which terraform; then
  (>2& echo "Terraform must be installed and in your path")
  exit 1
fi

for provider in $IAAS; do
    $BASE/${provider}/scripts/provision.sh
done
