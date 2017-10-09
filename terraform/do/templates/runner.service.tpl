[Unit]
Description=Runner

[Service]
EnvironmentFile=/etc/default/runner
ExecStart=/usr/local/bin/runner start --jobs /var/lib/jobs/${type}/${profile}.yaml
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
