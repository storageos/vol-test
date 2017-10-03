#!/usr/bin/env bats

load ../../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

@test "create cluster with defaults" {
  $short_run $prefix storageos $cliopts cluster create
  assert_success
  echo $output | egrep '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  assert_success
  $short_run $prefix storageos $cliopts cluster rm $output
  assert_success
}

@test "create cluster with valid size (3)" {
  $short_run $prefix storageos $cliopts cluster create -s 3
  assert_success
  $short_run $prefix storageos $cliopts cluster rm $output
  assert_success
}

@test "create cluster with invalid size (4)" {
  $short_run $prefix storageos $cliopts cluster create -s 4
  assert_failure

  # No need to remove, they shouldn't exist, and $output won't be ID's
  # but an error message
  #
  #run $prefix storageos $cliopts cluster rm $output
  #assert_success
}

@test "delete cluster" {
  $short_run $prefix storageos $cliopts cluster create
  assert_success
  $short_run $prefix storageos $cliopts cluster rm $output
  assert_success
  $short_run $prefix storageos $cliopts cluster inspect $output
  assert_failure
}

@test "cluster inspect with defaults" {
  $short_run $prefix storageos $cliopts cluster create
  id=$output
  $short_run $prefix storageos $cliopts cluster inspect $id
  $short_run $prefix storageos $cliopts cluster inspect $id --format {{.ID}}
  assert_output $id
  $short_run $prefix storageos $cliopts cluster inspect $id --format {{.Size}}
  assert_output 3
  $short_run $prefix storageos $cliopts cluster rm $id
  assert_success
}

@test "cluster health before nodes joined using cluster id" {
  $short_run $prefix storageos $cliopts cluster create
  $short_run $prefix storageos $cliopts cluster health $output
  assert_failure
  assert_output "No cluster nodes found"
}

@test "cluster health existing cluster using bad api" {
  $short_run $prefix STORAGEOS_HOST=999.999.999.999 storageos $cliopts cluster health
  assert_failure
  assert_output "API not responding to list nodes: Get http://999.999.999.999:5705/version: dial tcp: lookup 999.999.999.999: no such host"
}

@test "cluster health existing cluster using api" {
  $short_run $prefix storageos $cliopts cluster health
  assert_success
}

@test "cluster health existing cluster using api" {
  $short_run $prefix storageos $cliopts cluster health
  assert_success
}

@test "cluster health default format" {
  $short_run $prefix storageos $cliopts cluster health
  assert_success
  assert_output --partial "KV"
  assert_output --partial "NATS"
  assert_output --partial "SCHEDULER"
  assert_output --partial "DFS_CLIENT"
  assert_output --partial "DFS_SERVER"
  assert_output --partial "DIRECTOR"
  assert_output --partial "FS_DRIVER"
  assert_output --partial "FS"  
}

@test "cluster health cp format" {
  $short_run $prefix storageos $cliopts cluster health --format cp
  assert_success
  assert_output --partial "KV"
  assert_output --partial "KV_WRITE"
  assert_output --partial "NATS"
  assert_output --partial "SCHEDULER"
}

@test "cluster health dp format" {
  $short_run $prefix storageos $cliopts cluster health --format dp
  assert_success
  assert_output --partial "DFS_CLIENT"
  assert_output --partial "DFS_SERVER"
  assert_output --partial "DIRECTOR"
  assert_output --partial "FS_DRIVER"
  assert_output --partial "FS"
}

@test "cluster health quiet" {
  $short_run $prefix storageos $cliopts cluster health --quiet
  assert_success
}

@test "cluster health quiet cp format" {
  $short_run $prefix storageos $cliopts cluster health --format cp --quiet
  assert_success
}

@test "cluster health quiet dp format" {
  $short_run $prefix storageos $cliopts cluster health --format dp --quiet
  assert_success
}

@test "cluster health raw format" {
  $short_run $prefix storageos $cliopts cluster health --format raw
  assert_success
}

@test "cluster health quiet raw format" {
  $short_run $prefix storageos $cliopts cluster health --format raw --quiet
  assert_success
}

@test "cluster health custom format" {
  $short_run $prefix storageos $cliopts cluster health --format {{.Node}}
  assert_success
}
