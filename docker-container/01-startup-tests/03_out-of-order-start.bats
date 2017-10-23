#!/usr/bin/env bats

load ../../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

# These tests attmpt to force a historic race-hazard to surface (See DEV-1707)
# Starting up the containers out of order (with large enough sleeps) should force this bug to be
# hit if it exists.

@test "Install containers on three nodes" {
  join=$(printf "%s:5705,%s:5705,%s:5705" "${prefix#*@}" "${prefix2#*@}" "${prefix3#*@}")

  declare -a arr=("$prefix2" "$prefix3" "$prefix")
  for i in "${arr[@]}"; do
    $long_run "$i" docker run -d --name storageos \
      -e JOIN="$join" \
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

    assert_success

    # Sleeping like this is rather aggressive, but gets the job done
    sleep 10
  done

  wait_for_cluster
}

@test "Verify cluster" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    printf "Checking state on %s\n" "$i"

    $short_run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

    [ "$hosts" -eq 3 ]
  done
}

@test "Remove containers" {
  run remove_nodes
  assert_success
}
