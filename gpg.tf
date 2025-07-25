resource "random_password" "passphrase" {
  length = 21
}

module "passphrase" {
  source             = "registry.infrahouse.com/infrahouse/secret/aws"
  version            = "1.0.2"
  secret_description = "Passphrase for a signing GPG key for ${var.repository_codename}"
  secret_name        = "packager-passphrase-${var.repository_codename}"
  secret_value       = random_password.passphrase.result
  tags               = local.default_module_tags
  readers            = var.signing_key_readers
  writers            = var.signing_key_writers
  environment        = var.environment
}

module "key" {
  source             = "registry.infrahouse.com/infrahouse/secret/aws"
  version            = "1.0.2"
  secret_description = "Signing GPG key for ${var.repository_codename}"
  secret_name        = "packager-key-${var.repository_codename}"
  tags               = local.default_module_tags
  readers            = var.signing_key_readers
  writers            = var.signing_key_writers
  environment        = var.environment
}
