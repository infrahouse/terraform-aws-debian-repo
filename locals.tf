locals {
  module_version = "4.0.0"

  default_module_tags = merge(
    {
      service : "debian-repo-${var.repository_codename}"
      created_by_module : "infrahouse/debian-repo/aws"
      environment : var.environment
    },
    var.tags,
  )
  origin_id          = "s3-${module.repo_bucket.bucket_name}"
  distributions_path = "${path.module}/files/distributions"
}
