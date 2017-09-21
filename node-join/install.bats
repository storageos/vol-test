#!/usr/bin/env bats

# is this test up to date?
load ../test_helper


@test "IP list join [INSTALL]" {
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  AIP2=$(echo $prefix2 | cut -f 2 -d'@')
  AIP3=$(echo $prefix3 | cut -f 2 -d'@')
  JOIN=$(printf "%s:5705,%s:5705,%s:5705" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$JOIN"

  #run $prefix docker run -d --name storageos \
  #  -e HOSTNAME \
  #  -e ADVERTISE_IP=$AIP1 \
  #  -e JOIN=$JOIN \
  #  --net=host \
  #  --pid=host \
  #  --privileged \
  #  --cap-add SYS_ADMIN \
  #  --device /dev/fuse \
  #  -v /var/lib/storageos:/var/lib/storageos:rshared \
  #  -v /run/docker/plugins:/run/docker/plugins \
  #  storageos/node server
  run $prefix docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
  assert_success

  run $prefix2 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
  assert_success

  run $prefix3 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
  assert_success
}

@test "IP list join [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

    echo "$hosts"
    [ "$hosts" -eq 3 ]
  done

}

@test "IP list join [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    #run $i docker container kill storageos
    #run $i docker container rm storageos
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}

@test "IP list join no port [INSTALL]" {
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  AIP2=$(echo $prefix2 | cut -f 2 -d'@')
  AIP3=$(echo $prefix3 | cut -f 2 -d'@')
  JOIN=$(printf "%s,%s,%s" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$JOIN"

  run $prefix docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
  assert_success

  run $prefix2 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
  assert_success

  run $prefix3 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
  assert_success
}

@test "IP list join no port [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

    echo "$hosts"
    [ "$hosts" -eq 3 ]
  done
}

@test "IP list join no port [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}
