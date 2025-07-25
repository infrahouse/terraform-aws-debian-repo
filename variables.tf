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

variable "environment" {
  description = "Name of environment."
  type        = string
}
variable "architectures" {
  description = "List of architectures served by the repo"
  type        = list(string)
  default = [
    "amd64"
  ]
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

variable "signing_key_readers" {
  description = "List of role ARNs that have permission to read GPG signing key and passphrase."
  type        = list(string)
  default     = null
}

variable "signing_key_writers" {
  description = "List of role ARNs that have permission to write to GPG signing key and passphrase secrets."
  type        = list(string)
  default     = null
}

variable "package_version_limit" {
  description = "Number of versions of a package to keep in the repository. Zero means keep all versions."
  type        = number
  default     = null
}

variable "tags" {
  description = "A map of tags to add to resources."
  default     = {}
}

variable "zone_id" {
  description = "Route53 zone id where the parent domain of var.domain_name is hosted. If var.domain_name is repo.foo.com, then the value should be zone_id of foo.com."
  type        = string
}
