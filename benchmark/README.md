# Stress tests and benchmark 'framework'

The Job runner allows to provision stress tests on top of regular storageos clusters.
They are run through the runner [code](http://code.storageos.net/projects/TOOL/repos/runner/browse)

When the pipeline is running it's entrypoint is `./stress-test-trigger.sh` or `./perf-test-trigger.sh` , this is fed the env variables in `envfile.sh`
configuring the IAAS for the stress tests, a pre-set setting of stress tests (low medium high) and whether the tests are run 
in containers or on the host straight..

## How it works

Note: since bash doesn't offer 'modular' programming, code organisation is done through conventions regarding folders:

- Each IAAS provider has a folder under `TLD/cloud-provisioners` (currently only '/do'), This folder must have a `scripts/new-cluster.sh` script 
which manages the configuration of stress test clusters within its `/do` folder, this is currently done with a layer of templating on top of terraform modules. 

The runner job config is the same for a particular cluster at a particular stress test or benchmark profile (eg `low`) and this config is run on every node using the runner and systemd.

We fix all stress test clusters to be 3 node clusters, this is easy to reconfigure in the `TLD/cloud-providers/templates/${stress,cluster}/cluster.template`

## conventions for development

In the following text, when we refer to TLD we mean top profile directory `vol-test/stress-tests` , `DODIR` refer to `TLD/cloudprovisioenrs/do` and `$PROFILE` a stress test profile used when triggering the tests.
 
Although the following conventions are not strictly enforced (you are free within an IAAS implementation) it will be relevant if your provider is using terraform (with modules)
and to understand the digital ocean IAAS in `DODIR`.

- In the `DODIR/cluster` folder you can see that we implemented a vanilla storageos cluster installation, see its documentation for more details. this is a win because these eventually can be community guides for each provider and we can fetch them over git with `terraform get`

- When the `DODIR/new-cluster` script is triggered, provided this is a new cluster, we copy the job profile from either `DODIR/jobs/container/$PROFILE` or `DODIR/jobs/host/$PROFILE` into the `configs/` folder. 

- we then run a template processing step with the env variables supplied, this instantiate the vanilla module with specific config (see `DODIR/variables.tf` and the `DODIR/scripts/new-cluster.sh`) this generates a unique teraform module instance and terraform applies it.
our terraform workspace is the `DODIR` folder in that case.. Please note that whatever SSH key you're using must be added to Digital Ocean before use through do webapp or cli/api.

* This means that the relevant terraform template (perf-cluster.template or stress-cluster.template) instantiates the module, copies runner, config , scripts and systemd unit and triggers the systemdunit.
the vanilla cluster has no logic that is specific to stress tests or perf tests *

at any point the terraform source for all clusters is contained in files named: `DODIR/$PROFILE-STORAGEOS_VERSION.tf`

- The templates/ directory in each IAAS contains `lib/bash-tempalter` templates, this is used to overcome shortcomings in terraform multi-modules. it generates the terraform sources for each cluster and the `DODIR/configs/$PROFILE-STORAGEOS_VERSION.service` systemd runner script.

- We copy the `node-scripts` directory (which will be scripts invoked by the runner)
It also contains systemd tempaltes which we use to add node restart behaviour to our runner.

the `node-scripts` directory (which is copied to every node) call to the script in the relevant `node-scripts/src` which contains the source script of Dockerfile.
This is self explanatory if you read the source from the job files which call the node-scripts (assuming they are in home root) which themselves are organised in src/

Sometimes these scripts are made 'compatible' between host and container run.. meaning that provided with the appropriate setup (mounting a disk natively or just creating it in storageos) and calls the same inner script to be DRY. (check kernel-compile for more details) don't be surprised by this.. just saving effort between making dockerfile and writing the script for host.

Please see (document on adding stress tests (or benchmark tests ))[http://wiki.storageos.net/display/DOC/Adding+a+stress+test+or+benchmark] for more details.
