locals {
  module_version = "3.0.1"

  default_module_tags = merge(
    {
      service : "debian-repo-${var.repository_codename}"
      created_by_module : "infrahouse/debian-repo/aws"
      environment : var.environment
    },
    var.tags,
  )
  # This is h
  origin_id          = "s3-${aws_s3_bucket.repo.bucket}"
  index_html_path    = "${path.module}/files/index.html"
  distributions_path = "${path.module}/files/distributions"
}
