variable "role_arn" {
  default = null
}
variable "test_zone" {}
variable "ubuntu_codename" {}
variable "http_user" {
  default = null
}
variable "http_password" {
  default = null
}
variable "jumphost_role_arn" {}
variable "jumphost_role_name" {}
variable "create_web_acl" {
  description = "Create a CLOUDFRONT-scope WAFv2 Web ACL that blocks all traffic, and associate it with the repository -- exercises web_acl_arn."
  type        = bool
  default     = false
}
