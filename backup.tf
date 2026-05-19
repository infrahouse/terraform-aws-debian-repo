data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.bucket_name}-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
  tags               = local.default_module_tags
}

resource "aws_iam_role_policy_attachment" "backup_s3" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
}

resource "aws_iam_role_policy_attachment" "restore_s3" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
}

module "backup_key" {
  source          = "registry.infrahouse.com/infrahouse/key/aws"
  version         = "0.3.0"
  environment     = var.environment
  key_description = "Encryption key for ${var.bucket_name} backup vault"
  key_name        = "${var.bucket_name}-backup"
  service_name    = "debian-repo-${var.repository_codename}"
  tags            = var.tags
}

resource "aws_backup_vault" "repo" {
  name          = "${var.bucket_name}-backup"
  kms_key_arn   = module.backup_key.kms_key_arn
  force_destroy = var.backup_force_destroy
  tags          = local.default_module_tags
}

resource "aws_backup_plan" "repo" {
  name = "${var.bucket_name}-backup"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.repo.name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.backup_retention_days
    }
  }

  tags = local.default_module_tags
}

resource "aws_backup_selection" "repo" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.bucket_name}-backup"
  plan_id      = aws_backup_plan.repo.id

  resources = [
    aws_s3_bucket.repo.arn
  ]
}