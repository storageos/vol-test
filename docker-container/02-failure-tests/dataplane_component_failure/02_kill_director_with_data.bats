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
  $short_run $prefix storageos $cliopts volume create directorTest
  assert_success

  # Ensure the mount-point exists
  $short_run $prefix mkdir -p /mnt/test-mounts/1
  assert_success

  $short_run $prefix storageos $cliopts volume mount directorTest /mnt/test-mounts/1
  assert_success

  # create a 10M file
  $short_run $prefix touch /mnt/test-mounts/1/binFile
  assert_success
  $long_run $prefix dd if=/dev/urandom of=/mnt/test-mounts/1/binFile bs=10M count=1
  assert_success

  # create a checksum
  $short_run $prefix touch /mnt/test-mounts/1/checksum
  assert_success
  $long_run $prefix /bin/bash -c 'md5sum /mnt/test-mounts/1/binFile > /mnt/test-mounts/1/checksum' # redirection must be quoted
  assert_success

}

@test "Unmount and kill process" {
  $short_run $prefix storageos $cliopts volume unmount directorTest
  assert_success

  # go and find the pid
  dir_pid=$(get_pid "$prefix" "storageos-director")
  refute [ -z $dir_pid ]

  # kill the process
  run $i kill -9 $dir_pid
  assert_success

  # Give the some process restart time
  sleep 5
}

@test "Remount and verify data" {
  $short_run $prefix storageos $cliopts volume mount directorTest /mnt/test-mounts/1
  assert_success

  $long_run $prefix md5sum --check /mnt/test-mounts/1/checksum
  assert_success
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

