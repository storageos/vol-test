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

@test "Ensure lock gets released" {
  # Give the cluster a chance to perform elections
  sleep 10

  $short_run $prefix storageos $cliopts node ls --format '{{.Address}},{{.Scheduler}}'
  assert_success

  # get the output as an array (split by newlines)
  old_ifs=$IFS
  IFS=$'\n'
  arr=("$output")
  IFS=$old_ifs

  # Find the leader node
  leader=""
  for i in "${arr[@]}"; do
    if [[ "$i" == *"true"* ]] ; then
      # this node has the lock
      leader=$(printf "root@%s" "${i%%*,}")
    fi
  done

  # Cannot continue if there is no leader
  [ "$leader" != "" ]

  # shutdown the leader
  $long_run $leader docker stop storageos
  assert_success

  # give time for the lock to expire
  sleep 30

  # we dont (trivialy) know which node was removed, so we have to try all of them
  combined=""
  declare -a nodes=("$prefix" "$prefix2" "$prefix3")
  for i in "${nodes[@]}"
  do
    add=$($i storageos $cliopts node ls --format '{{.Address}},{{.Scheduler}}')
    combined="${combined}${add}"
  done

  # ensure there is a new leader
  [[ "$combined" == *"true"* ]]
}

@test "Remove containers" {
  run remove_nodes
  assert_success
}

