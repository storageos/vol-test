[Unit]
Description=Runner

[Service]
Environment=INFLUX_CONN=${influxdb_uri}
ExecStart=/usr/local/bin/runner start --jobs /var/lib/jobs/${type}/${profile}

[Install]
WantedBy=multi-user.target
