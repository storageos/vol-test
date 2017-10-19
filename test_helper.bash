#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2153

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

load "$DIR/test/test_helper/bats-support/load.bash"
load "$DIR/test/test_helper/bats-assert/load.bash"

driver="$VOLDRIVER"
prefix="$PREFIX"
prefix2="$PREFIX2"
prefix3="$PREFIX3"
createopts="$CREATEOPTS"
pluginopts="$PLUGINOPTS"
cliopts="$CLIOPTS"

# This string replace is UGLY, but it works for now
node_driver=${driver/plugin/node}

# OSX appears to not have timeout(1) by default, and the copy in coreutils is called gtimeout.
# Almost everything however will have some kind of perl 5 variant.
# This ugly one liner seemed less ugly than which + alias magic, and doesn't require coreutils.
function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

# takes env pairs as args, eg. "install_nodes 'JOIN=192.168.0.2' 'OTHERVAR=othervalue'"
function install_nodes {
  extra_env=""

  # build set of aditional env vars
  for i in "$@"; do
      extra_env+=$(printf -- '-e %s ' "$i")
  done
  printf "Adding additional env vars:\n\t%s\n" "$extra_env"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    long_timeout "$i" docker run -d --name storageos \
      "$extra_env" \
      -e HOSTNAME \
      -e ADVERTISE_IP="${i#*@}" \
      --net=host \
      --pid=host \
      --privileged \
      --cap-add SYS_ADMIN \
      --device /dev/fuse \
      -v /var/lib/storageos:/var/lib/storageos:rshared \
      -v /run/docker/plugins:/run/docker/plugins \
      "$node_driver" server
    # ensure that the node was installed
    [ $? -eq 0 ]
  done
}

function remove_nodes {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    # long_timeout "$i" docker stop storageos
    long_timeout "$i" docker stop storageos
    long_timeout "$i" docker rm storageos
    long_timeout "$i" umount /var/lib/storageos/volumes
    long_timeout "$i" rm -rf /var/lib/storageos
  done
}

function get_pid {
    ssh_prefix=$1
    proc_name=$2

    rtn_pid=$($ssh_prefix docker container top storageos | grep $proc_name | egrep -o '([0-9]+)' | head -n 1)

    # The caller can capture this
    echo $rtn_pid
}

# wait a reasonable time for a command to complete before stopping it and returning
# returns 124 or 128+9 on timeout (the latter if the command required sigkill)
function ui_timeout {
  timeout_duration=10
  # kill_after=1 # additional time to wait after sending signal before killing

  # Our timeout alternative doesn't support kill after behaviour, an asumption is made that the
  # child processes will not be atempting to catch SIGALARM. If this turns out to not be the case
  # then we will need to reconsider.
  #timeout -k $kill_after $timeout_duration $@
  timeout $timeout_duration $@
  exit_status=$?

  # timed out
  if [[ $exit_status -eq 124 ]]; then
      echo "Command timed out"
  fi

  # timed out, and needed to be killed (status 128+9)
  if [[ $exit_status -eq 137 ]]; then
      echo "Command timed out, and needed to be killed"
  fi

  return $exit_status
}

# wait a longer time for a command to complete before stopping it and returning
# returns 124 or 128+9 on timeout (the latter if the command required sigkill)
function long_timeout {
  timeout_duration=120
  # kill_after=20 # additional time to wait after sending signal before killing

  # Our timeout alternative doesn't support kill after behaviour, an asumption is made that the
  # child processes will not be atempting to catch SIGALARM. If this turns out to not be the case
  # then we will need to reconsider.
  # timeout -k $kill_after $timeout_duration $@
  timeout $timeout_duration $@
  exit_status=$?

  # timed out
  if [[ $exit_status -eq 124 ]]; then
      echo "Command timed out"
  fi

  # timed out, and needed to be killed (status 128+9)
  if [[ $exit_status -eq 137 ]]; then
      echo "Command timed out, and needed to be killed"
  fi

  return $exit_status
}

# Wait for the cluster to become available
function wait_for_cluster {
  no_of_nodes=${1:-"3"}
  max_time=${2:-"30"}

  printf "VARS %s %s\n" "$no_of_nodes" "$max_time"

  for ((number=0;number<max_time;number++))
  {
    sleep "1s"
    health=$($prefix storageos -u storageos -p storageos cluster health --format '{{.KV}}{{.NATS}}{{.Scheduler}}') || true

    # iff the command suceeds check the output
    if [[ "$health" != "" ]]; then
      # iff we can see all the nodes check the health
      if [[ $(echo "$health" | wc -l) -eq $no_of_nodes ]]; then
        ok=1

        # Every line should read 'alive' for all services
        while read -r line; do
          if [[ "$line" != "alivealivealive" ]]; then
            ok=0
          fi
        done <<< "$health"

        # Iff all are healthy, return early
        if [[ ok -eq 1 ]]; then
          # extra safety sleep to wait for API router switch
          # should go away once there is an API state in the health status
          sleep 5
          return 0
        fi

      fi
    fi
  }

  # Timeout - time to return
  # extra safety sleep to wait for API router switch
  # should go away once there is an API state in the health status
  sleep 5
  return 0
}

# Wait for the cluster to be available and volumes are provisionable
function wait_for_volumes {
    wait_for_cluster "$1"
    sleep "15s" # CP has a safety sleep on newly provisioned nodes
    return 0
}
