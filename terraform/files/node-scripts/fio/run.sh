#!/bin/bash

# this script will be continually executed from the runner
# it will be running on every node
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 product testtype blocksize [replicas] [cache true/false]"
  exit 1
fi

PRODUCT=$1
TEST_TYPE=$2
BLKSIZE=$3
REPLICAS=${4:-0}
CACHE=${5:-false}

volname=$(uuidgen | cut -c1-5)
filename="unset"

# Provision volume
case $PRODUCT in

  native)
    filename=/root/$volname
    dd if=/dev/zero of=$filename bs=1M count=1024
    VERSION=""
    ;;

  storageos)
    cli_auth="-u ${STORAGEOS_USERNAME:-storageos} -p ${STORAGEOS_PASSWORD:-storageos}"

    if [ $REPLICAS -gt 0 ]; then
      LABELS="--label storageos.feature.replicas=${REPLICAS}"
    fi

    if [ $CACHE == "false" ]; then
      LABELS="$LABELS --label storageos.feature.nocache=true"
    fi

    storageos $cli_auth volume create $LABELS $volname
    if [ $? -ne 0 ]; then
      (>2& echo "volume create failed")
      exit 2
    fi

    volid=$(storageos $CREDS volume inspect default/$volname --format {{.ID}})
    filename=/var/lib/storageos/volumes/$volid
    ;;

  *)
    (>2& echo "unsupported product type, 1st param must be one of 'native' or 'storageos'")
    exit 1
    ;;

esac

out=$(mktemp)
fio --output-format=json $DIR/$TEST_TYPE.fio --bs=$BLKSIZE --filename $filename > $out
if [ $? -ne 0 ]; then
  (>2& echo "fio command failed")
  exit 2
fi

if [[ -n $INFLUXDB_URI ]]; then
  TAGS="volname=${volname}"
  [[ -n $BLKSIZE ]] && TAGS="$TAGS,blocksize=${BLKSIZE}"
  [[ -n $REPLICAS ]] && TAGS="$TAGS,replicas=${REPLICAS}"
  [[ -n $CACHE ]] && TAGS="$TAGS,cache=${CACHE}"
  [[ -n $HO[STNAME ]] && TAGS="$TAGS,host=${HOSTNAME}"
  [[ -n $CPU ]] && TAGS="$TAGS,cpus=${CPU}"
  [[ -n $MEMORY ]] && TAGS="$TAGS,memory=${MEMORY}"
  [[ -n $PRODUCT ]] && TAGS="$TAGS,product=${PRODUCT}"
  [[ -n $VERSION ]] && TAGS="$TAGS,version=${VERSION}"
  fiord influxdb --input $out --uri $INFLUXDB_URI --db=${INFLUXDB_DBNAME:-fio} --tags $TAGS
  if [ $? -ne 0 ]; then
    (>2& echo "fiord command failed")
    exit 3
  fi
fi

# Clean-up
case $PRODUCT in
  native)
    rm $filename
    ;;
  storageos)
    storageos $cli_auth volume rm default/$volname
    ;;
esac

# rm $out
exit 0
