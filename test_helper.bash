#!/usr/bin/env bats

# shellcheck disable=SC2034,SC2153

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

load "$DIR/test/test_helper/bats-support/load.bash"
load "$DIR/test/test_helper/bats-assert/load.bash"

driver="$VOLDRIVER"
prefix="$PREFIX"
prefix2="$PREFIX2"
prefix3="$PREFIX3"
createopts="$CREATEOPTS"
pluginopts="$PLUGINOPTS"
cliopts="$CLIOPTS"


# wait a reasonable time for a command to complete before stopping it and returning
# returns 124 or 128+9 on timeout (the latter if the command required sigkill)
function ui_timeout {
  timeout_duration=10
  kill_after=1 # additional time to wait after sending signal before killing

  timeout -k $kill_after $timeout_duration $@
  exit_status=$?

  # timed out
  if [[ $exit_status -eq 124 ]]; then
      echo "Command timed out"
  fi

  # timed out, and needed to be killed (status 128+9)
  if [[ $exit_status -eq 137 ]]; then
      echo "Command timed out, and needed to be killed"
  fi

  return $exit_status
}

# wait a longer time for a command to complete before stopping it and returning
# returns 124 or 128+9 on timeout (the latter if the command required sigkill)
function long_timeout {
  timeout_duration=120
  kill_after=20 # additional time to wait after sending signal before killing

  timeout -k $kill_after $timeout_duration $@
  exit_status=$?

  # timed out
  if [[ $exit_status -eq 124 ]]; then
      echo "Command timed out"
  fi

  # timed out, and needed to be killed (status 128+9)
  if [[ $exit_status -eq 137 ]]; then
      echo "Command timed out, and needed to be killed"
  fi

  return $exit_status

}
