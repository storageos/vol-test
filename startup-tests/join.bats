#!/usr/bin/env bats

# is this test up to date?
load ../test_helper


@test "IP list join [INSTALL]" {
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  AIP2=$(echo $prefix2 | cut -f 2 -d'@')
  AIP3=$(echo $prefix3 | cut -f 2 -d'@')
  join=$(printf "%s:5705,%s:5705,%s:5705" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$join"

  #run $prefix docker run -d --name storageos \
  #  -e HOSTNAME \
  #  -e ADVERTISE_IP=$AIP1 \
  #  -e JOIN=$join \
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
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$join
    assert_success
  done

  sleep 5
}

@test "IP list join [VERIFY]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    printf "Checking state on %s\n" "$i"

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
  join=$(printf "%s,%s,%s" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$join"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$join
    assert_success
  done

  sleep 5
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
  join=$(printf "http://%s:5705,http://%s:5705,http://%s:5705" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$join"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$join
    assert_success
  done

  sleep 5
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
  join=$(printf "http://%s,http://%s,http://%s" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$join"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$join
    assert_success
  done

  sleep 5
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
  join=$(printf "%s:5705,http://%s,http://%s:5705" "$AIP1" "$AIP2" "$AIP3")

  printf "Doing install-time join: %s\n" "$join"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$join
    assert_success
  done

  sleep 5
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

  join=$output

  printf "Doing install-time join: %s\n" "$join"

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$join
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

@test "join after volume create [INSTALL]" {
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  join=$(printf "%s:5705" "$AIP1")

  # One node for now
  run $prefix docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$join
  assert_success

  # Need to do a long wait until DEV-1645 is fixed
  sleep 30
}

@test "join after volume create [VERIFY]" {
  echo "Creating volume"
  run $prefix storageos $cliopts volume create -n default foo
  assert_success

  echo "Installing on nodes 2 & 3"
  AIP1=$(echo $prefix | cut -f 2 -d'@')
  AIP2=$(echo $prefix2 | cut -f 2 -d'@')
  AIP3=$(echo $prefix3 | cut -f 2 -d'@')

  run $prefix2 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$(printf "%s:5705,%s:5705" "$AIP1" "AIP2")
  assert_success

  run $prefix3 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$(printf "%s:5705,%s:5705,%s:5705" "$AIP1" "AIP2" "AIP3")
  assert_success

  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  echo "Confirming volume exists on all nodes"
  for i in "${arr[@]}"
  do
    run $i storageos $cliopts volume ls --format {{.Name}}
    assert_success

    volumes=$(echo $output | wc -w)
    printf "There should be one volume in output:\n%s\n" "$output"
    [ "$volumes" -eq 1 ]
  done

}

@test "join after volume create [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}
