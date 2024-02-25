resource "aws_s3_object" "distributions" {
  bucket = aws_s3_bucket.repo.bucket
  key    = "conf/distributions"
  content = templatefile(
    local.distributions_path,
    {
      codename : var.repository_codename
      signwith : var.gpg_sign_with
    }
  )
  content_type = "text/plain"
  tags         = local.tags
}
