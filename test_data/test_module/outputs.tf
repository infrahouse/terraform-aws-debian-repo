output "release_bucket" {
  description = "Bucket name that hosts repository files."
  value       = module.test.release_bucket
}

output "release_bucket_arn" {
  description = "Bucket ARN that hosts repository files."
  value       = module.test.release_bucket_arn
}

output "packager_key_secret_arn" {
  description = "ARN of a secret that will store a GPG private key."
  value       = module.test.packager_key_secret_arn
}

output "packager_key_secret_id" {
  description = "Identifier of a secret that will store a GPG private key."
  value       = module.test.packager_key_secret_id
}

output "packager_key_passphrase_secret_arn" {
  description = "ARN of a secret that will store a GPG private key passphrase."
  value       = module.test.packager_key_passphrase_secret_arn
}

output "packager_key_passphrase_secret_id" {
  description = "Identifier of a secret that will store a GPG private key passphrase."
  value       = module.test.packager_key_passphrase_secret_id
}

output "repository_url" {
  value = module.test.repo_url
}

output "jumphost" {
  value = module.jumphost.jumphost_hostname
}

output "jumphost_role" {
  value = module.jumphost.jumphost_role_arn
}
