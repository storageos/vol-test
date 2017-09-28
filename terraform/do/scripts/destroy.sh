#!/bin/bash -e

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/..

export TF_VAR_pvt_key_path=${PVTK_PATH:=~/.ssh/id_rsa}
export TF_VAR_pub_key_path=${PUBK_PATH:=~/.ssh/id_rsa.pub}
export TF_VAR_ssh_fingerprint=$(ssh-keygen -lf $TF_VAR_pub_key_path -E md5 | awk '{ print $2 }' | cut -d ':' -f 2-)

pushd $PROJECT_DIR

terraform destroy

popd
