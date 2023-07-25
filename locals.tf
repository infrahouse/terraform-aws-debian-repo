locals {
  origin_id          = "s3-${aws_s3_bucket.repo.bucket}"
  index_html_path    = "${path.module}/files/index.html"
  distributions_path = "${path.module}/files/distributions"
}
