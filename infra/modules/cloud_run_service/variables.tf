variable "project_id" {}
variable "region" {}
variable "name" {}
variable "image" {}
variable "service_account_email" {}
variable "cpu" { default = "0.5" }
variable "memory" { default = "512Mi" }
variable "concurrency" { default = 80 }
variable "min_instances" { default = 0 }
variable "max_instances" { default = 5 }
variable "ingress" { default = "INGRESS_TRAFFIC_ALL" }
variable "env_vars" {
  type    = map(string)
  default = {}
}
