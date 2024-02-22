output "repo_url" {
  description = "Repository URL."
  value       = "https://${var.domain_name}"
}

output "release_bucket" {
  description = "Bucket name that hosts repository files."
  value       = aws_s3_bucket.repo.bucket
}

output "release_bucket_arn" {
  description = "Bucket ARN that hosts repository files."
  value       = aws_s3_bucket.repo.arn
}

output "packager_key_secret_arn" {
  description = "ARN of a secret that will store a GPG private key."
  value       = aws_secretsmanager_secret.key.arn
}

output "packager_key_secret_id" {
  description = "Identifier of a secret that will store a GPG private key."
  value       = aws_secretsmanager_secret.key.id
}

output "packager_key_passphrase_secret_arn" {
  description = "ARN of a secret that will store a GPG private key passphrase."
  value       = aws_secretsmanager_secret.passphrase.arn
}

output "packager_key_passphrase_secret_id" {
  description = "Identifier of a secret that will store a GPG private key passphrase."
  value       = aws_secretsmanager_secret.passphrase.id
}
