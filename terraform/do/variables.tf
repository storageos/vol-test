variable "build" {
  description = "build reference"
  default = "unset"
}

variable "type" {
  description = "build type, stress or benchmark"
}

variable "profile" {
  description = "test profile, low, medium, high or custom"
}

variable "storageos_version" {
  description = "storageos version"
  default = "0.8.1"
}


variable "do_token" {}
variable "pub_key_path" {}
variable "pvt_key_path" {}

# variable "log_user" {
#   description = "http auth username for fluentd collector agent"
# }

# variable "log_pass" {
#   description = "http auth password for fluentd collector agent"
# }
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