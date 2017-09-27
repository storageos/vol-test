#!/bin/bash

# Test wrapper script.
# You can run with environment variables, or
# run this script with uncommented vars and
# appropriate values to your environment.

#VOLDRIVER=yourorg/volume-plugin:tag
#PREFIX=ssh 192.168.42.97
#PREFIX2=ssh 192.168.42.75
#PLUGINOPTS='PLUGIN_API_KEY="keystring goes here" PLUGIN_API_HOST="192.168.42.97"'
#CREATEOPTS='-o profile=database'

# Wrap pushd and popd so directory names don't appear on the
# console with no explanation.

pushd () {
    echo "++ Directory '$*'"
    command pushd "$@" > /dev/null
}

popd () {
    command popd > /dev/null
}

if ! [[ -f user_provision.sh ]]; then
  BATS_OPTS='-u'
fi

echo "Loading test.env"
. ./test.env

# Dump config (for pipeline logs).
cat <<EOF

Configuration
=============
Item          Env var   Value
-----------------------------------
Driver        VOLDRIVER $VOLDRIVER
Host 1        PREFIX    $PREFIX
Host 2        PREFIX2   $PREFIX2
Host 3        PREFIX3   $PREFIX3
Host tag      DO_TAG    $DO_TAG
==
EOF

pushd docker-plugin
echo "-----------------------------"
echo "installing plugin on 3 nodes"
echo "-----------------------------"
pushd ./install
  bats $BATS_OPTS .
popd

echo "Pause for cluster init"
sleep 30
echo "End cluster init pause"

echo "-----------------------------"
echo "running docker acceptance tests"
echo "-----------------------------"
pushd ./docker-tests
# these docker provided tests have to be done in order
  bats $BATS_OPTS singlenode.bats secondnode.bats
popd
popd

for d in acceptance-tests/** ; do
  echo "-----------------------------"
  echo  "$d bats suite running"
  echo "-----------------------------"
  pushd "$d"
   bats $BATS_OPTS .
  popd
done
