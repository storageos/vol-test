#!/bin/bash -ex 
BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Only source env if vars aren't set (by Jenkins) so it can be run manually
if [[ -z $IAAS ]]; then
  set -a
  . envfile.sh
  set +a
fi

# TODO: provision new key and add to jenkins slaves

[ -z $TF_VAR_type ] && (>2& echo "TF_VAR_type must be set to benchmark or stress"; exit 1)

if [ -z $TF_VAR_profile ]; then
  case $TF_VAR_type in
    "benchmark")
      export TF_VAR_profile="bench-all"
      ;;
    "stress")
      export TF_VAR_profile="low"
      ;;
    *)
      (>2& echo "Unknown test type, TF_VAR_type should be set to benchmark or stress")
      exit 1
  esac
fi

if [ -z $TF_VAR_build ]; then
  if [ -z $BUILD_TAG ]; then
    BUILD_TAG=$(whoami)
  fi
  export TF_VAR_build=$BUILD_TAG
fi

if [[ -z $TF_VAR_profile ]] || [[ -z "$TF_VAR_storageos_version" ]]; then
  (>2& echo "Please specify the Job you want to run and the container version") 
  exit 1
fi

if ! which terraform; then
  (>2& echo "Terraform must be installed and in your path") 
  exit 1
fi

for provider in $IAAS; do
    $BASE/terraform/${provider}/scripts/provision.sh 
done 
