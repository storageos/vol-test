#!/usr/bin/env bats

# is this test up to date?
load ../test_helper


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
