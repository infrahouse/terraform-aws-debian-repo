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

variable "backup_force_destroy" {
  description = "If true, the backup vault will be destroyed even if it contains recovery points."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain S3 backups."
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_days >= 1
    error_message = "backup_retention_days must be at least 1."
  }
}

variable "backup_schedule" {
  description = <<-EOT
    Cron expression for the backup schedule in AWS Backup format.
    Default is daily at 5:00 AM UTC.
  EOT
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "domain_name" {
  description = "Domain name where the repository will be available."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., development, staging, production). Used for resource tagging and identification."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}
variable "architectures" {
  description = "List of architectures served by the repo"
  type        = list(string)
  default = [
    "amd64"
  ]
}

variable "gpg_public_keys" {
  description = <<-EOT
    Armored GPG public keys to publish for repository verification. They are concatenated into the
    single published key object (DEB-GPG-KEY-<domain_name>); apt trusts a Release signed by any key
    in the resulting keyring. During a signing-key rotation this holds both the outgoing and
    incoming keys so clients trust a Release signed by either. Each list element is a full armored
    public key block.

    The private signing key(s) are uploaded out-of-band with
    'ih-secrets set packager-key-<codename> ~/packager-key-<codename>'.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.gpg_public_keys) >= 1
    error_message = "gpg_public_keys must contain at least one armored GPG public key."
  }
}

variable "gpg_sign_with" {
  description = <<-EOT
    Signing key identifier(s) for reprepro's SignWith in conf/distributions. Accepts a packager
    email or one or more space-separated GPG key IDs / fingerprints. During a key rotation, set this
    to both the outgoing and incoming key IDs to dual-sign the repository.
  EOT
  type        = string
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

variable "replication_region" {
  description = "AWS region for the S3 cross-region replication replica buckets."
  type        = string
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
