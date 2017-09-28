#!/bin/bash -x


# this script will be continually executed from the runner
# it will be running on every node
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

USAGE="Usage: $0 testtype blocksize disktype"

if [ "$#" -ne "3" ]; then
  echo "$USAGE"
  exit 1
fi

TEST_TYPE=$1
BSIZE=$2
DOPTIONS=$3

voluid=$(uuidgen | cut -c1-5)

# waiting for controller to be healthy..
sleep 30


case $DOPTIONS in
  1-rep)
    LABELS="--label storageos.feature.replicas=1"
    ;;
  2-rep)
    LABELS="--label storageos.feature.replicas=2"
    ;;
  no-cache)
    LABELS="--label storageos.feature.nocache=true"
    ;;
  **)
    LABELS=""
    ;;
esac

if [[ $TEST_TYPE == "basic" ]]; then
  RW="randread"  
else
  RW="randwrite"
fi

CREDS="-u storageos -p storageos"
storageos $CREDS volume create $LABELS $voluid

STORAGEOS_VOLID=$(storageos $CREDS volume inspect default/$voluid | jq --raw-output '.[] | .id')

OUTPUT="tee -a"
if [[ -n $INFLUX_CONN ]]; then
  TAGS="hostname=$(hostname),bs=${BSIZE},rw=${RW},test_type=${TEST_TYPE},options=${DOPTIONS}"
  OUTPUT="fiord influxdb --uri $INFLUX_CONN --db=fio --tags $TAGS"
fi

fio --output-format=json $DIR/$TEST_TYPE.fio --bs=$BSIZE --filename /var/lib/storageos/volumes/$STORAGEOS_VOLID --rw $RW | $OUTPUT

storageos $CREDS volume rm default/$voluid

