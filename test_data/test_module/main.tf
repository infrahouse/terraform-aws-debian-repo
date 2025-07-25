resource "random_pet" "bucket_suffix" {}

module "test" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }

  source                = "../../"
  bucket_name           = "infrahouse-${random_pet.bucket_suffix.id}"
  domain_name           = "debian-repo-test.${data.aws_route53_zone.cicd.name}"
  gpg_public_key        = file("${path.module}/files/DEB-GPG-KEY-infrahouse-${var.ubuntu_codename}")
  gpg_sign_with         = "packager-${var.ubuntu_codename}@infrahouse.com"
  repository_codename   = var.ubuntu_codename
  bucket_force_destroy  = true
  zone_id               = data.aws_route53_zone.cicd.zone_id
  http_auth_user        = var.http_user
  http_auth_password    = var.http_password
  bucket_admin_roles    = [var.jumphost_role_arn]
  signing_key_writers   = [var.jumphost_role_arn]
  package_version_limit = 0
  environment           = "development"
}
