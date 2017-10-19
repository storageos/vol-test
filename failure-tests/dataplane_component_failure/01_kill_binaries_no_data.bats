#!/usr/bin/env bats

load ../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

@test "Install containers on three nodes" {
  join=$(printf "%s:5705,%s:5705,%s:5705" "${prefix#*@}" "${prefix2#*@}" "${prefix3#*@}")

  run install_nodes "JOIN=$join"
  assert_success

  wait_for_cluster
}

@test "Check storageos-director restart" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    # go and find the pid
    dir_pid=$(get_pid $prefix "storageos-director")
    [ -n $dir_pid ]

    # kill the process
    run "$i" kill -9 $dir_pid
    assert_success

    # Give the some process restart time
    sleep 5

    # assert that it is running again (has been re-started)
    [ -n $(get_pid $prefix "storageos-director") ]
  done
}

@test "Check fs-director restart" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    # go and find the pid
    fs_dir_pid=$(get_pid $prefix "fs-director")
    [ -n $fs_dir_pid ]

    # kill the process
    run "$i" kill -9 $fs_dir_pid
    assert_success

    # Give the some process restart time
    sleep 5

    # assert that it is running again (has been re-started)
    [ -n $(get_pid $prefix "fs-director") ]
  done
}

@test "Check rdbplugin restart" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    # go and find the pid
    rdb_pid=$(get_pid $prefix "rdbplugin")
    [ -n $rdb_pid ]

    # kill the process
    run "$i" kill -9 $rdb_pid
    assert_success

    # Give the some process restart time
    sleep 5

    # assert that it is running again (has been re-started)
    [ -n $(get_pid $prefix "rdbplugin") ]
  done
}

# Not entirely sure what this component is, need to find out
@test "Check client restart" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    # go and find the pid
    client_pid=$(get_pid $prefix "storageos-client")
    [ -n $client_pid ]

    # kill the process
    run "$i" kill -9 $client_pid
    assert_success

    # Give the some process restart time
    sleep 5

    # assert that it is running again (has been re-started)
    [ -n $(get_pid $prefix "storageos-client") ]
  done
}

# Not entirely sure what this component is, need to find out
@test "Check server restart" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"; do
    # go and find the pid
    server_pid=$(get_pid $prefix "storageos-client")
    [ -n $server_pid ]

    # kill the process
    run "$i" kill -9 $server_pid
    assert_success

    # Give the some process restart time
    sleep 5

    # assert that it is running again (has been re-started)
    [ -n $(get_pid $prefix "storageos-client") ]
  done
}

@test "Remove containers" {
  run remove_nodes
  assert_success
}

