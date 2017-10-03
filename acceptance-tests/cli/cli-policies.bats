#!/usr/bin/env bats

load ../../test_helper

short_run="run ui_timeout"
long_run="run long_timeout"

@test "create policy" {
  $short_run $prefix storageos $cliopts user create policyTestUser --role user --password policiesAreCool
  assert_success

  $short_run $prefix storageos $cliopts user create policyTestGroupUser --role user --password policiesAreCool --groups policyTestGroup
  assert_success

  $short_run $prefix storageos $cliopts namespace create policytestnamespace
  assert_success

  $short_run $prefix storageos $cliopts policy create --user policyTestUser --namespace policytestnamespace
  assert_success

  $short_run $prefix storageos $cliopts policy create --group policyTestGroup --namespace policytestnamespace
  assert_success
}

@test "policy enforcement" {
  $short_run $prefix storageos $cliopts user create unprivileged --role user --password policiesAreCool
  assert_success

  $short_run $prefix storageos -u unprivileged -p policiesAreCool volume create myVol --namespace policytestnamespace
  assert_failure

  $short_run $prefix storageos -u policyTestUser -p policiesAreCool volume create myVol --namespace policytestnamespace
  assert_success

  $short_run $prefix storageos -u policyTestGroupUser -p policiesAreCool volume create myOtherVol --namespace policytestnamespace
  assert_success
}
