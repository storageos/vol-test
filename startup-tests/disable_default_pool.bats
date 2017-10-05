#!/usr/bin/env bats

# is this test up to date?
load ../test_helper

@test "Disable default pool, all nodes [INSTALL]" {
  id=$($prefix storageos cluster create)
  declare -a arr=("$prefix" "$prefix2" "$prefix3")
  for i in "${arr[@]}"
  do
    run $i docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$id LABEL_ADD='disableDefaultPool=true'
    assert_success
  done

  wait_for_cluster
}

@test "Disable default pool, all nodes [VERIFY]" {
  # Test that the labels get set
  run $prefix storageos $cliopts node ls --format {{.Labels}}
  assert_success
  expected_output=$(printf 'disableDefaultPool=true\ndisableDefaultPool=true\ndisableDefaultPool=true\n')

  # Handy for debug
  diff <(echo ${output}) <(echo ${expected_output})

  [ "$output" == "$expected_output" ]

  # Test that they are not in the pool
  run $prefix storageos $cliopts pool inspect default --format {{.ControllerNames}}
  assert_success
  assert_output "[]"
}

@test "Disable default pool, all nodes [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}

@test "Disable default pool, single node [INSTALL]" {
  id=$($prefix storageos cluster create)

  run $prefix docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$id LABEL_ADD='disableDefaultPool=true'
  assert_success

  run $prefix2 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$id
  assert_success

  run $prefix3 docker plugin install --alias storageos --grant-all-permissions $driver JOIN=$id
  assert_success

  wait_for_cluster
}

@test "Disable default pool, single node [VERIFY]" {
  # Test that the labels get set
  run $prefix storageos $cliopts node ls --format {{.Labels}}
  assert_success
  expected_output=$(printf 'disableDefaultPool=true\n\n\n')

  # Handy for debug
  diff <(echo ${output}) <(echo ${expected_output})

  [ "$output" == "$expected_output" ]

  # Grab the JSON for jq
  run $prefix storageos $cliopts pool inspect default
  assert_success

  # Test that there are two nodes in the pool
  run jq '.[0].controllerNames | length' <(echo ${output})
  assert_success
  assert_output "2"
}

@test "Disable default pool, single node [TEARDOWN]" {
  declare -a arr=("$prefix" "$prefix2" "$prefix3")

  for i in "${arr[@]}"
  do
    run $i docker plugin rm -f storageos
    run $i rm -rf /var/lib/storageos/kv
    assert_success
  done
}
