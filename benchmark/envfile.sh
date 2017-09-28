#!/bin/bash 

# list of envs expected for this script, sourceable
IAAS="do" # currently do and kubeadm

TF_VAR_profile="bench-all" # low high or medium for stress  bench-all or bench-small-read for bench

TF_VAR_storageos_version="0.8.1" # valid docker hub container eg. storageos/node:0.8.0

TF_VAR_es_host=${ES_HOST:-logs.storageos.cloud}
TF_VAR_es_port=${ES_PORT:-9200}
# ES_USER="foo"
# ES_PASS="bar"

TF_VAR_influxdb_uri=${INFLUXDB_URI:-"http://influxdb.storageos.cloud:8086"}

# PVTK_PATH=~/.ssh/id_rsa
# PUBK_PATH=~/.ssh/id_rsa.pub
