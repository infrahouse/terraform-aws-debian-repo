resource "aws_s3_bucket" "repo" {
  bucket        = var.bucket_name
  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_acl" "repo" {
  bucket = aws_s3_bucket.repo.bucket
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo
  ]
}

resource "aws_s3_bucket_public_access_block" "repo" {
  bucket                  = aws_s3_bucket.repo.bucket
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "repo" {
  bucket = aws_s3_bucket.repo.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_website_configuration" "repo" {
  bucket = aws_s3_bucket.repo.bucket
  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_policy_document" "public-access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.repo.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "public-access" {
  bucket = aws_s3_bucket.repo.bucket
  policy = data.aws_iam_policy_document.public-access.json
  depends_on = [
    aws_s3_bucket_acl.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo,
    aws_s3_bucket_website_configuration.repo,
  ]
}

resource "aws_s3_object" "index-html" {
  bucket = aws_s3_bucket.repo.bucket
  key    = "index.html"
  content = templatefile(
    "${path.module}/files/index.html",
    {
      title : var.index_title,
      body : var.index_body
    }
  )
  acl          = "public-read"
  content_type = "text/html"
  depends_on = [
    aws_s3_bucket_acl.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo,
    aws_s3_bucket_website_configuration.repo
  ]
}

resource "aws_s3_object" "deb-gpg-public-key" {
  bucket       = aws_s3_bucket.repo.bucket
  key          = "DEB-GPG-KEY-${var.domain_name}"
  content      = var.gpg_public_key
  acl          = "public-read"
  content_type = "text/plain"
  depends_on = [
    aws_s3_bucket_acl.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo,
    aws_s3_bucket_website_configuration.repo
  ]
}

resource "aws_s3_bucket" "repo-logs" {
  bucket        = "${var.bucket_name}-logs"
  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_ownership_controls" "repo-logs" {
  bucket = aws_s3_bucket.repo-logs.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "repo-logs" {
  depends_on = [
    aws_s3_bucket_ownership_controls.repo-logs
  ]
  bucket = aws_s3_bucket.repo-logs.bucket
  acl    = "private"
}
