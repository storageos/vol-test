This is the baseline script for benchmarks and currently only contains CPU
baselines using storageos_bench tool. getting the dependencies for this tool required us
to modify the `templates/perf-cluster.template` to add the get-deps script in `node-scripts/src/get-deps`
One challenge we faced to add the netbenchmark once we decide on the format for representing ping/throughput between connection pairs in influxdb... 
