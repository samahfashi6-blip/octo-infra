variable "project_id" {}
variable "account_id" {}
variable "display_name" {}
variable "project_roles" {
  type    = list(string)
  default = []
}
