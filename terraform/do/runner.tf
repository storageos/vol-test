
module "storageos_cluster"  {
  source = "./cluster"
  do_token = "${var.do_token}"
  region="${var.region}"
  tag="${var.type}-${var.build}"
  cluster_size="${var.nodes}"
  machine_size="${var.memory}"
  pvt_key_path="${var.pvt_key_path}"
  ubuntu_version="${var.os}"
  cli_version="${var.storageos_cli_version}"
  es_host="${var.es_host}"
  es_port="${var.es_port}"
  es_user="${var.es_user}"
  es_pass="${var.es_pass}"
  node_container_version="${var.storageos_version}"
  ssh_fingerprint="${var.ssh_fingerprint}"
}

output "hostnames" {
  value = "${module.storageos_cluster.hostnames}"
}

output "addresses" {
  value = "${module.storageos_cluster.ip-addrs}"
}

data "template_file" "runner-service" {
  template = "${file("templates/runner.service.tpl")}"

  vars {
    type = "${var.type}"
    profile = "${var.profile}"
    influxdb_uri = "${var.influxdb_uri}"
  }
}

resource "null_resource" "runner" {

  count = 3

  connection {
    type = "ssh"
    user = "root"
    host = "${element(module.storageos_cluster.ip-addrs, count.index)}"
    private_key = "${file(var.pvt_key_path)}"
    timeout = "10s"
  }

  /* copy the bundled binaries */
  provisioner "file" {
    source = "./bin"
    destination = "/usr/local/"
  }

  /* copy the job config binary */
  provisioner "file" {
    source = "./jobs"
    destination = "/var/lib/jobs"
  }

  /* store useful vars for attaching to metrics */
  provisioner "file" {
    content = <<EOF
HOSTNAME="${element(module.storageos_cluster.hostnames, count.index)}"
INFLUXDB_URI="${var.influxdb_uri}"
STORAGEOS_USERNAME=storageos
STORAGEOS_PASSWORD=storageos
TYPE="${var.type}"
PROFILE="${var.profile}"
CPU=1
MEMORY="${var.memory}"
OS="${var.os}"
PRODUCT="storageos"
VERSION="${var.storageos_version}"
EOF
    destination = "/etc/default/runner"
  }

  /* copy runner systemd file */
  provisioner "file" {
    content = "${data.template_file.runner-service.rendered}"
    destination = "/etc/systemd/system/runner.service"
  }

  /* copy scripts for jobs */
  provisioner "file" {
    source = "./node-scripts"
    destination = "~/"
  }

  provisioner "remote-exec" {
    inline = ["DEBIAN_FRONTEND=noninteractive apt -q -y install fio jq build-essential bc fping",
      "chmod -R u+x /usr/local/bin/* ~/node-scripts/**",
      "~/node-scripts/src/get-deps/install-deps.sh",
      "systemctl enable runner --now"
    ]
  }
}

