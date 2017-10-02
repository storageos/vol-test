#!/bin/bash

# list of envs expected for this script, sourceable
IAAS="do" # currently do and kubeadm

# TF_VAR_profile="default" # default, low or high

# TF_VAR_storageos_version="0.8.1" # valid docker hub container eg. storageos/node:0.8.0

# TF_VAR_es_host="logs.storageos.cloud"
# TF_VAR_es_port="9200"
# TF_VAR_es_user="foo"
# TF_VAR_es_pass="bar"

# TF_VAR_influxdb_uri="http://influxdb.storageos.cloud:8086"

# Theese are read/set in terraform/*/provision.sh
# PVTK_PATH=~/.ssh/id_rsa
# PUBK_PATH=~/.ssh/id_rsa.pub

TF_VAR_es_user="access"
TF_VAR_es_pass="keetoh6I"
TF_VAR_do_token="5143aa72a299dca1eb396d9e3592c0fed09bb8acefa2670b352e46fad5e46ae6"
TF_VAR_influxdb_uri="http://admin:Letmein1@influxdb.storageos.cloud:8086"

