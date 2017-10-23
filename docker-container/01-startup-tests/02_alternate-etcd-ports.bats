#!/usr/bin/env bats

load ../../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

@test "Setup cluster with alternate etcd ports" {
  join=$(printf "%s:5705,%s:5705,%s:5705" "${prefix#*@}" "${prefix2#*@}" "${prefix3#*@}")

  run install_nodes "JOIN=$join" "KV_CLIENT_PORT=5712" "KV_PEER_PORT=5713" "LOG_LEVEL=debug"
  assert_success

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
