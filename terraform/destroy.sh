#!/bin/bash -e

BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Only source env if vars aren't set (by Jenkins) so it can be run manually
if [ -f $BASE/envfile.sh ]; then
  set -a
  . $BASE/envfile.sh
  set +a
fi

if ! which terraform; then
  (>2& echo "Terraform must be installed and in your path")
  exit 1
fi

for provider in $IAAS; do
  $BASE/${provider}/scripts/destroy.sh $@
done
