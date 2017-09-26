#!/bin/bash

set -e
declare -a ips

plugin_name="${PLUGIN_NAME:-soegarots/plugin}"
version="${VERSION:-latest}"
cli_branch="${CLI_BRANCH:-}"
cli_version="${CLI_VERSION:-0.0.12}"

branch_env_file="./branch-env.txt"


# Set up branch_env. The pipeline sets BRANCH_ENV to the current branch.
#
# - If BRANCH_ENV is not set in the environment:
#   - Try to load from $branch_env_file in the pwd
#   - Otherwise set using uuidgen
# - Otherwise (BRANCH_ENV is set)
#   - Use the first 16 characters of the given branch
#
# Note that branch_env is concatenated with the build number. This means
# that we don't reuse tags for Pipeline builds (as the build number changes)
# but we do for local runs. This is the intended behaviour - build separately
# for each pipeline build, but reuse aggressively for local builds.
#
branch_env="${BRANCH_ENV:-branchnotset}"
# Make sure branch_env has at most 16 characters.
if [ "$branch_env" = "branchnotset" ]; then
    if [ -s $branch_env_file ]; then
      branch_env="$(cat $branch_env_file)"
      echo "Loaded preset branch_env='$branch_env'"
    else
      branch_env="$(uuidgen | cut -c1-13)"
      echo "Saving branch_env='$branch_env'"
      echo "$branch_env" >$branch_env_file
    fi
else
    branch_env="$(echo "$branch_env" | cut -c1-16)"
fi

build_id="${branch_env}-${BUILD:-buildnotset}"
tag="vol-test-${build_id}"
region=lon1
size=2gb
name_template="${tag}-${size}-${region}-"
snapshot_name="vol-test-snapshot"

if [[ -f user_provision.sh ]] && [[  -z "$JENKINS_JOB" ]]; then
    echo "Loading user settings overrides from user_provision.sh"
    . ./user_provision.sh
fi

# Check $PLUGIN_NAME is properly-formed. It's easy to specify storageos/plugin:latest
# when storageos/plugin is needed - use $VERSION for the tag.
if [[ $plugin_name =~ : ]]; then
  echo "PLUGIN_NAME='$plugin_name' doesn't look right, use PLUGIN_NAME to specify the image, and VERSION to specify the tag"
  exit 1
fi

# The correct way to check out a ref from git depends on the
# type of reference.
function git_checkout_ref() {
  local newref
  newref="$1"
  if [ -z "$newref" ]; then
    echo "Function usage: ${FUNCNAME[0]} refspec" >&2
    exit 1
  fi

  if git show-ref --verify "refs/tags/$newref"; then
    # It's a tag.
    echo "Checkout tag '$newref'"
    git checkout -b "$newref" "$newref"

  elif git show-ref --verify "refs/heads/$newref"; then
    # It's a branch.
    echo "Checkout branch '$newref'"
    git checkout "$newref"

  else
    # Don't know what it is, treat as branch and accept the consequences.
    echo "Checkout unknown ref '$newref'"
    git checkout "$newref"
  fi
}

# Can't use arbitrary git branch/tag names as docker tags.
function git_branch_to_tag() {
  local branch
	branch="${1:-}"
	if [ -z "$branch" ]; then
		error "Function usage: ${FUNCNAME[0]} BRANCH"
	fi
	echo -n "$branch" | tr -C 'a-zA-Z0-9' '_' | tr -s '_'
	echo
}

function download_storageos_cli()
{
  local build_id

  if [ -z "$cli_branch" ]; then
    echo "Downloading CLI version ${cli_version}"
    export cli_binary=storageos_linux_amd64-${cli_version}

    if [[ ! -f $cli_binary ]]; then
      curl --fail -sSL "https://github.com/storageos/go-cli/releases/download/${cli_version}/storageos_linux_amd64" > "$cli_binary"
      chmod +x "$cli_binary"
    fi

    echo "Testing downloaded CLI using Docker"
    if ! docker run -v "$(pwd)":/mnt ubuntu:xenial /mnt/"$cli_binary" --help >/dev/null; then
      echo "Failed to run storageos binary '$cli_binary', removing it" >&2
      rm $cli_binary
      exit 1
    fi

  else
    # Build the binary.
    echo "Building CLI from source, branch ${cli_branch}"
    export cli_binary=storageos_linux_amd64
    rm -rf cli_build ${cli_binary}
    # Check out the upstream repository.
    git clone https://github.com/storageos/go-cli.git cli_build
    pushd cli_build
    if [ "$cli_branch" != master ]; then
      git_checkout_ref "$cli_branch"
    fi
    # Check we know how to build this binary.
    if [ ! -f Dockerfile ]; then
      echo "Ref '$cli_branch' has no Dockerfile, so we don't know how to build it" >&2
      exit 1
    fi
    docker_tag="$(git_branch_to_tag "$cli_branch")"
    docker build -t "cli_build:${docker_tag}" .
    popd
    # Need to run a container and copy the file from it. Can't copy from the image.
    build_id="$(docker run -d "cli_build:${docker_tag}" version)"
    echo "Copy binary out of container"
    docker cp "${build_id}:/storageos" "${cli_binary}"
    chmod +x "${cli_binary}"
    rm -rf cli_build
  fi
}

function provision_do_nodes()
{
  droplets=$($doctl_auth compute droplet list --tag-name "${tag}" --format ID --no-header)

  if [[ -z "${droplets}" ]] || [[ -n "$JENKINS_JOB" ]] || [[ -n "$BOOTSTRAP"  ]]; then
    echo "Creating new droplets"
    $doctl_auth compute tag create "$tag"
    for name in ${name_template}01 ${name_template}02 ${name_template}03; do
      id=$($doctl_auth compute droplet create \
        --image "$image" \
        --region $region \
        --size $size \
        --ssh-keys $SSHKEY \
        --tag-name "$tag" \
        --format ID \
        --no-header "$name")
      droplets+=" ${id}"
    done
  else
    for droplet in $droplets; do
      echo "Rebuilding existing droplet ${droplet}"
      $doctl_auth compute droplet-action rebuild "$droplet" --image "$image"
    done
  fi

  for droplet in $droplets; do
    status=""
    echo -n "Waiting for active status on droplet $droplet"
    while [[ "$status" != "active" ]]; do
      echo -n .
      sleep 1
      status=$($doctl_auth compute droplet get "$droplet" --format Status --no-header)
    done
    echo

    TIMEOUT=30
    ip=''
    echo -n "Fetching IP address for droplet $droplet"
    until [[ -n $ip ]] || [[ $TIMEOUT -eq 0 ]]; do
      echo -n .
      ip=$($doctl_auth compute droplet get "$droplet" --format PublicIPv4 --no-header)
      ips+=($ip)
      TIMEOUT=$((--TIMEOUT))
    done
    echo

    if [ $TIMEOUT -eq 0 ]; then
      echo "Failed to fetch droplet IP address" >&2
      exit 1
    fi

    echo -n "$droplet: Waiting for SSH on $ip"
    TIMEOUT=120
    until nc -z -w1 "$ip" 22 || [[ $TIMEOUT -eq 0 ]] ; do
      echo -n .
      sleep 1
      TIMEOUT=$((--TIMEOUT))
    done
    echo

    if [ $TIMEOUT -eq 0 ]; then
      echo "SSH didn't appear to start on $ip" >&2
      exit 1
    fi

    ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts

    echo "$droplet: Copying StorageOS CLI"
    scp -p "$cli_binary" "root@${ip}:/usr/local/bin/storageos"
    ssh "root@${ip}" "export STORAGEOS_USERNAME=storageos >>/root/.bashrc"
    ssh "root@${ip}" "export STORAGEOS_PASSWORD=storageos >>/root/.bashrc"

  done
}

function fetch_snapshot_id() {
  # Requires: snapshot_name
  # Exports: snapshot_id

  echo "Fetching ID for snapshot '$snapshot_name'"
  snapshot_id=$($doctl_auth compute image list-user --format Name,ID | grep -E "^${snapshot_name} " | awk '{print $2}')
  if [ -z "$snapshot_id" ]; then
    echo "Failed to fetch ID for snapshot name '$snapshot_name'"
    exit 1
  fi
}

function do_auth_init()
{

  # WE DO NOT MAKE USE OF DOCTL AUTH INIT but rather append the token to every request
  # this is because in a non-interactive jenkins job, any way of passing input (Heredoc, redirection) are ignored
  # with an 'unknown terminal' error we instead alias doctl and use the -t option everywhere
  export doctl_auth snapshot_name

  if [[ -z $DO_TOKEN ]] ; then
    echo "please ensure that your DO_TOKEN is entered in user_provision.sh"
    exit 1
  fi

  doctl_auth="doctl -t $DO_TOKEN"

  export image
  # image=$($doctl_auth compute image list --public  | grep docker-16-04 | awk '{ print $1 }') # ubuntu on linux img

  fetch_snapshot_id
  echo "Using image $snapshot_id"
  image="$snapshot_id"
}

function write_config()
{
  cat << EOF > test.env
export VOLDRIVER="${plugin_name}:${version}"
export CLIOPTS="-u storageos -p storageos"
export PREFIX="ssh root@${ips[0]}"
export PREFIX2="ssh root@${ips[1]}"
export PREFIX3="ssh root@${ips[2]}"
export DO_TAG="${tag}"
EOF

  echo "SUCCESS!  Ready to run tests:"
  echo "  ./run_volume_tests.sh"
  echo " Your environment credentials will be in test.env .. you may source it to interact with it manually"

}

function MAIN()
{
   # set -x
   do_auth_init
   download_storageos_cli
   provision_do_nodes
   # set +x
   write_config
}

MAIN
