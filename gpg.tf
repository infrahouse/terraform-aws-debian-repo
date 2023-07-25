resource "random_password" "passphrase" {
  length = 21
}

resource "aws_secretsmanager_secret" "passphrase" {
  name                    = "packager-passphrase-${var.repository_codename}"
  description             = "Passphrase for a signing GPG key for ${var.repository_codename}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "passphrase" {
  secret_id     = aws_secretsmanager_secret.passphrase.id
  secret_string = random_password.passphrase.result
}

resource "aws_secretsmanager_secret" "key" {
  name                    = "packager-key-${var.repository_codename}"
  description             = "Signing GPG key for ${var.repository_codename}"
  recovery_window_in_days = 0
}
