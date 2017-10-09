variable "build" {
  description = "build reference (e.g. Jenkins job id)"
  default = "unset"
}

variable "os" {
  description = "OS version"
  default = "ubuntu-16-04-x64"
}

variable "memory" {
  description = "machine RAM size (eg. 2gb)"
  default = "2gb"
}

variable "type" {
  description = "build type: stress or benchmark"
  default = ""
}

variable "profile" {
  description = "test profile: default, low, or high"
  default = "default"
}

variable "storageos_image" {
  description = "storageos image (defaults to storageos/node)"
  default = "storageos/node"
}

variable "storageos_version" {
  description = "storageos version"
  default = "0.8.1"
}

variable "storageos_cli_version" {
  description = "storageos cli version"
  default = "0.0.13"
}

variable "nbd" {
  description = "nbd kernel module enable"
  default = "true"
}

variable "nodes" {
  description = "number of nodes in cluster"
  default = "3"
}

variable "region" {
  description = "cloud provider region"
  default = "lon1"
}


variable "do_token" {}
variable "pub_key_path" {}
variable "pvt_key_path" {}
variable "ssh_fingerprint" {}

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

variable "influxdb_uri" {
  description = "InfluxDB URI for stats data"
  default = ""
}