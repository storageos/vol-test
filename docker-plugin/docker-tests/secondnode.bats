#!/usr/bin/env bats

load "../../test_helper"

short_run="run ui_timeout"
long_run="run long_timeout"

@test "Test: Install plugin for driver (storageos) on node 2" {
  #skip "This test works, faster for rev without it"
  $short_run $prefix2 -t "docker plugin ls | grep storageos"
  if [[ $status -eq 0 ]]; then
    skip
  fi

  $long_run $prefix2 docker plugin disable storageos -f
  $long_run $prefix2 docker plugin rm storageos
  $long_run $prefix2 docker plugin install --grant-all-permissions --alias storageos $driver $pluginopts
  assert_success

  wait_for_volumes
}

@test "Test: Confirm volume is visible on second node (volume ls) using driver (storageos)" {
  $short_run $prefix2 docker volume ls
  assert_line --partial "testvol"
}

@test "Start a container and mount the volume on node 2" {
  $long_run $prefix2 docker run -i -d --name mounter -v testvol:/data ubuntu /bin/bash
  assert_success
}

@test "Confirm textfile contents on the volume from node 2" {
  $short_run $prefix2 docker exec -i mounter cat /data/foo.txt
  assert_line --partial "testdata"
}

@test "Confirm checksum for binary file on node 2" {
  $short_run $prefix2 docker exec -i mounter md5sum --check /data/checksum
  assert_success
}

@test "Stop container on node 2" {
  $long_run $prefix2 docker stop mounter
  assert_success
}

@test "Destroy container on node 2" {
  $long_run $prefix2 docker rm mounter
  assert_success
}

@test "Remove volume" {
  $short_run $prefix2 docker volume rm testvol
  assert_success
}

@test "Confirm volume is removed from docker ls" {
  sleep 10
  $short_run $prefix2 docker volume ls
  refute_output --partial 'testvol'
}
