resource "random_password" "passphrase" {
  length = 21
}

module "passphrase" {
  source             = "registry.infrahouse.com/infrahouse/secret/aws"
  version            = "0.5.0"
  secret_description = "Passphrase for a signing GPG key for ${var.repository_codename}"
  secret_name        = "packager-passphrase-${var.repository_codename}"
  secret_value       = random_password.passphrase.result
  tags               = local.tags
  readers            = var.signing_key_readers
  writers            = var.signing_key_writers
}

module "key" {
  source             = "registry.infrahouse.com/infrahouse/secret/aws"
  version            = "0.5.0"
  secret_description = "Signing GPG key for ${var.repository_codename}"
  secret_name        = "packager-key-${var.repository_codename}"
  tags               = local.tags
  readers            = var.signing_key_readers
  writers            = var.signing_key_writers
}
