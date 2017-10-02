# Terraform cluster builds

Terraform is used to build clusters for running the benchmarks and stress tests.

## Quick-start cluster

```bash
export TF_VAR_do_token=<digitalocean token>
./provision.sh
```

After about 5 minutes you will be given a list of hostnames and addresses.

ssh to the hosts as root, using your standard private key:

```bash
ssh root@<ip addres>
```

## Conventions

Terraform variables are used directly and have the prefix `TF_VAR_`.  Terraform
will use default variables where possible, and error if not available.  This
reduces the amount of boilerplate in scripts.

## Profiles

When `TF_VAR_type` is set to `benchmark` or `stress`, a set of jobs will be run
on each node of the cluster.  Jobs are defined in `terraform/jobs/${TF_VAR_type}/${TF_VAR_profile}.yaml`
where `TF_VAR_profile` is typically the intensity level of the tests (default is `default`).

Tests are run by `runner`: [code](http://code.storageos.net/projects/TOOL/repos/runner/browse)
`runner` accepts a yaml definition of jobs, and allows you to specify the
command to run, env and args, whether the job should be restarted on exit, and
whether it should be run in isolation or in parallel with other jobs.

## Cloud providers

Currently only Digital Ocean is supported, but the intention is to add more.

Each new cloud provider should have a `scripts/provision.sh` and
`scripts/destroy.sh` within the cloud provider's subdirectory.

## Conventions for development

- The `<cloud provider>/cluster` implements a vanilla storageos cluster.  The
intention is to keep this as standard as possible so that we can re-use for
customer documentation/examples.  There is currently some specific config such
as central logging configuration that should be moved out.

- See (document on adding stress tests (or benchmark tests ))[http://wiki.storageos.net/display/DOC/Adding+a+stress+test+or+benchmark] for changing tests.
