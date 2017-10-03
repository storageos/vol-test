#!/usr/bin/env bats

load ../../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

@test "auth - incorrect user not allowed" {
  $short_run $prefix storageos -u wrong-user volume ls
  refute [[ $status -eq 0 ]]
}

@test "auth - incorrect pass not allowed" {
  $short_run $prefix storageos -p wrong-pass volume ls
  refute [[ $status -eq 0 ]]
}


