variable "project_id" {}
variable "account_id" {}
variable "display_name" {}
variable "description" {
  type    = string
  default = ""
}
variable "project_roles" {
  type    = list(string)
  default = []
}
