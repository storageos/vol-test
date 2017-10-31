#!/usr/bin/env bats

load ../../../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

@test "Install containers on three nodes" {
  join=$(printf "%s:5705,%s:5705,%s:5705" "${prefix#*@}" "${prefix2#*@}" "${prefix3#*@}")

  run install_nodes "JOIN=$join"
  assert_success

  wait_for_cluster
}

@test "Create and mount volume with data" {
  skip "not implemented"
}

@test "Unmount and kill process" {
  skip "not implemented"
}

@test "Remount and verify data" {
  skip "not implemented"
}

@test "Kill process while mounted" {
  skip "not implemented"
}

@test "Verify data" {
  skip "not implemented"
}

@test "Remove containers" {
  run remove_nodes
  assert_success
}

