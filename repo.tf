resource "aws_s3_object" "distributions" {
  bucket = aws_s3_bucket.repo.bucket
  key    = "conf/distributions"
  content = templatefile(
    local.distributions_path,
    {
      codename : var.repository_codename
      signwith : var.gpg_sign_with
      architectures : join(" ", var.architectures)
      package_version_limit : var.package_version_limit
    }
  )
  content_type = "text/plain"
  tags         = local.default_module_tags
}
