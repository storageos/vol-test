#!/usr/bin/env bats

load "../../test_helper"

short_run="run ui_timeout"
long_run="run long_timeout"

@test "Test: Install plugin " {
  #skip "Faster for rev during development without it - leave driver installed"
  $short_run $prefix -t "docker plugin ls | grep storageos"
  if [[ $status -eq 0 ]]; then
    skip
  fi

  $long_run $prefix docker plugin disable storageos -f
  $long_run $prefix docker plugin rm storageos
  $long_run $prefix docker plugin install --grant-all-permissions --alias storageos $driver $pluginopts
  assert_success

  wait_for_volumes
}

@test "Test: Create volume using driver (storageos)" {
  $short_run $prefix docker volume create --driver storageos $createopts testvol
  assert_success
}

@test "Test: Confirm volume is created (volume ls)" {
  $short_run $prefix docker volume ls
  assert_line --partial "testvol"
}

@test "Test: Confirm docker volume inspect works using driver (storageos)" {
  $short_run $prefix docker volume inspect testvol
  assert_line --partial "\"Driver\": \"storageos:latest"
}

@test "Start a container and mount the volume" {
  $long_run $prefix docker run -i -d --name mounter -v testvol:/data ubuntu /bin/bash
  assert_success
}

@test "Write a textfile to the volume" {
  $short_run $prefix 'docker exec -i -d mounter /bin/bash -c "echo \"testdata\" > /data/foo.txt"'
  assert_success
}

@test "Confirm textfile contents on the volume" {
  $short_run $prefix docker exec -i mounter cat /data/foo.txt
  assert_line --partial "testdata"
}

@test "Create a binary file" {
  $long_run $prefix docker exec -i 'mounter dd if=/dev/urandom of=/data/random bs=10M count=1'
  assert_output --partial "10 M"
}

@test "get a checksum for that binary file" {
  $long_run $prefix 'docker exec -i -d mounter /bin/bash -c "md5sum /data/random > /data/checksum"'
  assert_success
}

@test "Confirm checksum" {
  $long_run $prefix docker exec -i -d mounter md5sum --check /data/checksum
  assert_success
}

@test "Stop container" {
  $long_run $prefix docker stop mounter
  assert_success
}

@test "Destroy container" {
  $long_run $prefix docker rm mounter
  assert_success
}

@test "Let's see if our data is still here" {
  $long_run $prefix docker run -i -d --name mounter -v testvol:/data ubuntu /bin/bash
  assert_success
}

@test "Confirm textfile contents are still on the volume" {
  $short_run $prefix docker exec -i mounter cat /data/foo.txt
  assert_line --partial "testdata"
}

@test "Confirm checksum persistence" {
  $long_run $prefix docker exec -i mounter md5sum --check /data/checksum
  assert_success
}

@test "Stop container" {
  $long_run $prefix docker stop mounter
  assert_success
}

@test "Destroy container" {
  $long_run $prefix docker rm mounter
  assert_success
}
