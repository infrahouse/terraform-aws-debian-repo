resource "random_pet" "bucket_suffix" {}

# CLOUDFRONT-scope Web ACLs must be created via the us-east-1 endpoint
# regardless of the distribution's own region -- same requirement as the ACM
# certificate, hence the aliased provider.
resource "aws_wafv2_web_acl" "test" {
  count    = var.create_web_acl ? 1 : 0
  provider = aws.aws-us-east-1

  name  = "debian-repo-test-${random_pet.bucket_suffix.id}"
  scope = "CLOUDFRONT"

  # Blocks everything unconditionally -- enough to prove the association
  # itself takes effect, without needing a real, testable source IP.
  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "debian-repo-test-${random_pet.bucket_suffix.id}"
    sampled_requests_enabled   = true
  }
}

module "test" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }

  source      = "../../"
  bucket_name = "infrahouse-${random_pet.bucket_suffix.id}"
  domain_name = "debian-repo-test.${data.aws_route53_zone.cicd.name}"
  gpg_public_keys = [
    file("${path.module}/files/DEB-GPG-KEY-infrahouse-${var.ubuntu_codename}")
  ]
  gpg_sign_with         = "packager-${var.ubuntu_codename}@infrahouse.com"
  repository_codename   = var.ubuntu_codename
  bucket_force_destroy  = true
  backup_force_destroy  = true
  zone_id               = data.aws_route53_zone.cicd.zone_id
  http_auth_user        = var.http_user
  http_auth_password    = var.http_password
  bucket_admin_roles    = [var.jumphost_role_arn]
  signing_key_writers   = [var.jumphost_role_arn]
  package_version_limit = 0
  environment           = "development"
  replication_region    = "us-west-2"
  web_acl_arn           = var.create_web_acl ? aws_wafv2_web_acl.test[0].arn : null
}
