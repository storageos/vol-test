
variable "ubuntu_version" {
  description = "Ubuntu version for digital ocean tags"
}

variable "tag" {
  description = "tag on cluster instances"
}

variable "cluster_size" {
  description = "size of storageos cluster"
}

variable "machine_size" {
  description = "RAM size of digital ocean droplet in cap (eg. 2gb)"
}

variable "cli_version" {
  description = "Version of cli to download on each node"
}

variable "storageos_image" {
  description = "storageos image"
}

variable "storageos_version" {
  description = "storageos version"
}

variable "region" {
  description = "digital ocean region for cluster"
}

variable "ssh_fingerprint" {
  description = "SSH fingerprint of key to add to digital ocean, must be already in account"
}

variable "nbd" {
  description = "nbd kernel module enable"
  default = "true"
}

variable "es_host" {
  description = "Elasticsearch host for fluentd collector agent"
  default = "logs.storageos.cloud"
}

variable "es_port" {
  description = "Elasticsearch port for fluentd collector agent"
  default = "9200"
}

variable "es_user" {
  description = "Elasticsearch username for fluentd collector agent"
}

variable "es_pass" {
  description = "Elasticsearch password for fluentd collector agent"
}

variable "do_token" {}
variable "pvt_key_path" {}


