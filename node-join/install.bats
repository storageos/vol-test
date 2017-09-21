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
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
    assert_success
  done
}

@test "IP list join [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

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

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
    assert_success
  done
}

@test "IP list join no port [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

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

@test "IP list join scheme [INSTALL]" {
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  AIP2=$(echo $prefix2 | cut -f 2 -d'@')
  AIP3=$(echo $prefix3 | cut -f 2 -d'@')
  JOIN=$(printf "http://%s:5705,http://%s:5705,http://%s:5705" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$JOIN"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
    assert_success
  done
}

@test "IP list join scheme [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

    [ "$hosts" -eq 3 ]
  done
}

@test "IP list join scheme [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}

@test "IP list join scheme no port [INSTALL]" {
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  AIP2=$(echo $prefix2 | cut -f 2 -d'@')
  AIP3=$(echo $prefix3 | cut -f 2 -d'@')
  JOIN=$(printf "http://%s,http://%s,http://%s" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$JOIN"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
    assert_success
  done
}

@test "IP list join scheme no port [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

    [ "$hosts" -eq 3 ]
  done
}

@test "IP list join scheme no port [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}

@test "IP list join mixture [INSTALL]" {
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  AIP2=$(echo $prefix2 | cut -f 2 -d'@')
  AIP3=$(echo $prefix3 | cut -f 2 -d'@')
  JOIN=$(printf "%s:5705,http://%s,http://%s:5705" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$JOIN"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
    assert_success
  done
}

@test "IP list join mixture [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

    [ "$hosts" -eq 3 ]
  done
}

@test "IP list join mixture [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}

@test "IP list join token [INSTALL]" {
  run $prefix storageos $cliopts cluster create
  assert_success

  JOIN=$output

  printf "Doing install-time join: %s\n" "$JOIN"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$JOIN
    assert_success
  done

  # Let the cluster settle
  sleep 10
}

@test "IP list join token [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i storageos $cliopts node ls --format {{.Name}}
    assert_success

    hosts=$(echo $output | wc -w)
    printf "There should be three hosts in output:\n%s\n" "$output"

    [ "$hosts" -eq 3 ]
  done
}

@test "IP list join token [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}
