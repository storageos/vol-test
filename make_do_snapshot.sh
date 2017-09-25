#!/bin/bash

set -e
declare -a ips

branch_env="${BRANCH_ENV:-branchnotset}"
branch_env_file="./branch-env.txt"

if [ -s $branch_env_file ]; then
  branch_env="$(cat $branch_env_file)"
  echo "Loaded preset branch_env='$branch_env'"
else
  branch_env="$(uuidgen | cut -c1-13)"
  echo "Saving branch_env='$branch_env'"
  echo "$branch_env" >$branch_env_file
fi

build_id="${branch_env}-${BUILD:-buildnotset}"
tag="vol-test-snapshot-${build_id}"
region=lon1
size=2gb
name_template="${tag}-${size}-${region}-"

master_name="${name_template}-master"
snapshot_name="vol-test-snapshot"

if [[ -f user_provision.sh ]] && [[  -z "$JENKINS_JOB" ]]; then
    echo "Loading user settings overrides from user_provision.sh"
    . ./user_provision.sh
fi

function destroy_tagged_nodes() {
  # Requires: tag doctl_auth
  local droplets

  echo "Will delete any nodes tagged '$tag'"

  droplets=$($doctl_auth compute droplet list --tag-name "${tag}" --format ID --no-header)

  if [ ! -z "${droplets}" ]; then
    for droplet in $droplets; do
      echo "Deleting existing droplet ${droplet}"
      $doctl_auth compute droplet rm -f "${droplet}"
    done
  fi

}

function provision_master_node()
{
  # requires: master_name doctl_auth image region size SSHKEY tag name
  # exports: droplets master_id
  local droplet ip TIMEOUT

  if [ -z "$master_name" ]; then
    echo "Function ${FUNCNAME[0]} requires $master_name to be defined and non-empty" >&2
    exit 1
  fi

  destroy_tagged_nodes

  echo "Creating master droplet"
  $doctl_auth compute tag create "$tag"
  name="$master_name"

  # It makes sense to --wait here because we're only creating one droplet.
  id=$($doctl_auth --verbose compute droplet create \
    --image "$image" \
    --region $region \
    --size $size \
    --ssh-keys $SSHKEY \
    --tag-name "$tag" \
    --format ID \
    --no-header "$name" \
    --wait)
  droplet="${id}"
  master_id="$id"

  while [[ "$status" != "active" ]]; do
    sleep 2
    status=$($doctl_auth compute droplet get "$droplet" --format Status --no-header)
  done

  sleep 5

  TIMEOUT=100
  ip=''
  until [[ -n $ip ]] || [[ $TIMEOUT -eq 0 ]]; do
    ip=$($doctl_auth compute droplet get "$droplet" --format PublicIPv4 --no-header)
    ips+=($ip)
    sleep 1
    TIMEOUT=$((--TIMEOUT))
  done

  echo "$droplet: Waiting for SSH on $ip"
  TIMEOUT=100
  until nc -zw 1 "$ip" 22 || [[ $TIMEOUT -eq 0 ]] ; do
    sleep 2
    TIMEOUT=$((--TIMEOUT))
  done
  sleep 5

  ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts
  echo "$droplet: Disabling firewall"
  until ssh "root@${ip}" "/usr/sbin/ufw disable"; do
    sleep 2
  done

  echo "$droplet: Enabling core dumps"
  ssh "root@${ip}" "ulimit -c unlimited >/etc/profile.d/core_ulimit.sh"
  ssh "root@${ip}" "export DEBIAN_FRONTEND=noninteractive && apt-get -qqy update && apt-get -qqy -o=Dpkg::Use-Pty=0 install systemd-coredump"

  # # Disable NBD pending http://jira.storageos.net/browse/DEV-1645
  # echo "$droplet: Enable NBD"
  # ssh "root@${ip}" "modprobe nbd nbds_max=1024"

  echo "$droplet: Remove ugly motd"
  ssh "root@${ip}" "rm -rf /etc/update-motd.d/99-one-click"
}

function snapshot_master_node() {
  # Requires: master_id master_name snapshot_name
  # Exports: snapshot_id
  local ssid id

  echo "Removing existing snapshots called '$snapshot_name'"
  ssid="$($doctl_auth compute snapshot list -o json | jq -r '. [] | select(.name == "vol-test-snapshot") | .id')"
  for id in $ssid; do
    echo "Remove $id"
    $doctl_auth compute snapshot delete -f "$id"
  done

  if [ -z "$master_id" ] || [ -z "$master_name" ]; then
    echo "Function ${FUNCNAME[0]} requires $master_id and $#master_name to be defined and non-empty" >&2
    exit 1
  fi

  echo "Powering off node $master_id"
  $doctl_auth compute droplet-action power-off "$master_id" --wait
  echo "Snapshotting master droplet ${master_name}(${master_id})"
  $doctl_auth --verbose compute droplet-action snapshot \
    --snapshot-name "$snapshot_name" \
    --format ID --no-header \
    --wait \
    "$master_id"
  fetch_snapshot_id
  echo "Created snapshot $snapshot_name ID $snapshot_id"
}

function remove_master_node() {
  # Requires: master_id master_name
  echo "Removing master droplet ${master_name}(${master_id})"
  $doctl_auth --verbose compute droplet rm -f "$master_id"
}

function fetch_snapshot_id() {
  # Requires: snapshot_name
  # Exports: snapshot_id
  snapshot_id=$($doctl_auth compute image list --format Name,ID | grep -E "^${snapshot_name} " | awk '{print $2}')
  if [ -z "$snapshot_id" ]; then
    echo "Failed to fetch ID for snapshot name '$snapshot_name'"
    exit 1
  fi
}

function test_snapshot_node() {
  # Requires: snapshot_id doctl_auth region size SSHKEY tag name
  local id ip testname

  testname=snapshot-test-$tag

  destroy_tagged_nodes

  echo "Starting node using snapshot ${snapshot_id}"

  id=$($doctl_auth --verbose compute droplet create \
    --image "$snapshot_id" --region $region --size $size --ssh-keys $SSHKEY \
    --tag-name "$tag" --format ID --no-header --wait \
    "$testname")

  test -n "$id" || (echo "Failed to create snapshot test droplet" >&2; exit 1)

  ip=$($doctl_auth --verbose compute droplet get "$id" --format PublicIPv4 --no-header)
  test -n "$ip" || (echo "Failed to get test node IP address" >&2; exit 1)

  echo "$testname: Waiting for SSH on $ip"
  TIMEOUT=100
  until nc -zw 1 "$ip" 22 || [[ $TIMEOUT -eq 0 ]] ; do
    sleep 1
    TIMEOUT=$((--TIMEOUT))
  done

  ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts
  ssh "root@${ip}" "uname -a"
  ssh "root@${ip}" "docker version"

  echo "$testname: Deleting node"
  $doctl_auth --verbose compute droplet rm -f "$id"

}

function do_auth_init()
{
  # WE DO NOT MAKE USE OF DOCTL AUTH INIT but rather append the token to every request
  # this is because in a non-interactive jenkins job, any way of passing input (Heredoc, redirection) are ignored
  # with an 'unknown terminal' error we instead alias doctl and use the -t option everywhere
  export doctl_auth

  if [[ -z $DO_TOKEN ]] ; then
    echo "please ensure that your DO_TOKEN is entered in user_provision.sh"
    exit 1
  fi

  doctl_auth="doctl -t $DO_TOKEN"

  export image
  image=$($doctl_auth compute image list --public  | grep docker-16-04 | awk '{ print $1 }') # ubuntu on linux img
}

function MAIN()
{
  do_auth_init
  provision_master_node
  snapshot_master_node
  remove_master_node
  # fetch_snapshot_id
  test_snapshot_node
}

MAIN
