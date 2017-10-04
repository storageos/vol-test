#!/usr/bin/env bats

load ../../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

@test "test cli login" {
  # Should fail as there are no creds set
  $short_run $prefix storageos volume ls
  assert_failure

  $short_run $prefix storageos login localhost --username storageos --password storageos
  assert_success

  # Should work as there are cached creds
  $short_run $prefix storageos volume ls
  assert_success

  $short_run $prefix storageos logout localhost
  assert_success

  # Should fail as there are no creds set
  $short_run $prefix storageos volume ls
  assert_failure
}
