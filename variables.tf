variable "bucket_admin_roles" {
  description = "List of AWS IAM role ARN that has permissions to upload to the bucket"
  type        = list(string)
  default     = []
}

variable "bucket_name" {
  description = "S3 bucket name for the repository."
  type        = string
}

variable "bucket_force_destroy" {
  description = "If true, the repository bucket will be destroyed even if it contains files."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name where the repository will be available."
  type        = string
}

variable "gpg_public_key" {
  description = "Content of the GPG public key used for signing the repository. Note, you'll have to upload the key manually or with 'ih-s3-reprepro ... set-secret-value packager-key-focal ~/packager-key-focal'"
}

variable "gpg_sign_with" {
  description = "Email of a packager user."
}

variable "http_auth_user" {
  description = "Username for HTTP basic authentication. If not specified, the authentication isn't enabled."
  type        = string
  default     = null
}

variable "http_auth_password" {
  description = "Password for HTTP basic authentication."
  type        = string
  default     = null
}

variable "index_title" {
  description = "Content of a title tag in index.html."
  type        = string
  default     = "Debian packages repository"
}

variable "index_body" {
  description = "Content of a body tag in index.html."
  type        = string
  default     = "Stay tuned!"
}

variable "repository_codename" {
  description = "Repository codename. Can be focal, jammy, etc."
  type        = string
}

variable "zone_id" {
  description = "Route53 zone id where the parent domain of var.domain_name is hosted. If var.domain_name is repo.foo.com, then the value should be zone_id of foo.com."
  type        = string
}
