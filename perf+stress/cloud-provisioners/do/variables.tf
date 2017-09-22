variable "tag" {
  description = "tag for stress test"
}

variable "do_token" {}
variable "pub_key_path" {}
variable "pvt_key_path" {}

variable "log_user" {
  description = "http auth username for fluentd collector agent"
}

variable "log_pass" {
  description = "http auth password for fluentd collector agent"
}
variable "ssh_fingerprint" {}


