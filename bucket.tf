resource "aws_s3_bucket" "repo" {
  bucket        = var.bucket_name
  force_destroy = var.bucket_force_destroy
}

resource "aws_s3_bucket_acl" "repo" {
  bucket = aws_s3_bucket.repo.bucket
  acl    = "private"
  depends_on = [
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo
  ]
}

resource "aws_s3_bucket_public_access_block" "repo" {
  bucket                  = aws_s3_bucket.repo.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "repo" {
  bucket = aws_s3_bucket.repo.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

data "aws_iam_policy_document" "bucket-access" {
  statement {
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
    condition {
      test     = "StringEquals"
      values   = [
        aws_cloudfront_distribution.repo.arn
      ]
      variable = "AWS:SourceArn"
    }
  }
}

resource "aws_s3_bucket_policy" "bucket-access" {
  bucket = aws_s3_bucket.repo.bucket
  policy = data.aws_iam_policy_document.bucket-access.json
  depends_on = [
    aws_s3_bucket_acl.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo,
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
  content_type = "text/html"
  depends_on = [
    aws_s3_bucket_acl.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo,
  ]
}

resource "aws_s3_object" "deb-gpg-public-key" {
  bucket       = aws_s3_bucket.repo.bucket
  key          = "DEB-GPG-KEY-${var.domain_name}"
  content      = var.gpg_public_key
  content_type = "text/plain"
  depends_on = [
    aws_s3_bucket_acl.repo,
    aws_s3_bucket_public_access_block.repo,
    aws_s3_bucket_ownership_controls.repo,
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

resource "aws_s3_bucket_logging" "server-logs" {
  bucket        = aws_s3_bucket.repo.bucket
  target_bucket = aws_s3_bucket.repo-logs.bucket
  target_prefix = "server-side/"
}
