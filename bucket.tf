module "repo_bucket" {
  source  = "registry.infrahouse.com/infrahouse/s3-bucket/aws"
  version = "0.6.0"

  bucket_name        = var.bucket_name
  force_destroy      = var.bucket_force_destroy
  enable_versioning  = true
  enable_acl         = true
  bucket_policy      = data.aws_iam_policy_document.bucket-access.json
  replication_region = var.replication_region
  tags               = local.default_module_tags
}

module "logs_bucket" {
  source  = "registry.infrahouse.com/infrahouse/s3-bucket/aws"
  version = "0.6.0"

  bucket_name        = "${var.bucket_name}-logs"
  force_destroy      = var.bucket_force_destroy
  enable_acl         = true
  replication_region = var.replication_region
  tags               = local.default_module_tags
}

data "aws_iam_policy_document" "bucket-access" {
  source_policy_documents = concat(
    [
      data.aws_iam_policy_document.bucket-cloudfront-access.json,
    ],
    [
      for doc in data.aws_iam_policy_document.bucket-admin : doc.json
    ]
  )
}

data "aws_iam_policy_document" "bucket-cloudfront-access" {
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
      test = "StringEquals"
      values = [
        aws_cloudfront_distribution.repo.arn
      ]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "bucket-admin" {
  count = length(var.bucket_admin_roles)
  statement {
    principals {
      identifiers = [
        var.bucket_admin_roles[count.index],
      ]
      type = "AWS"
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

resource "aws_s3_bucket_logging" "server-logs" {
  bucket        = module.repo_bucket.bucket_name
  target_bucket = module.logs_bucket.bucket_name
  target_prefix = "server-side/"
}

resource "aws_s3_object" "index-html" {
  bucket = module.repo_bucket.bucket_name
  key    = "index.html"
  content = templatefile(
    "${path.module}/files/index.html",
    {
      title : var.index_title,
      body : var.index_body
    }
  )
  content_type = "text/html"
  tags         = local.default_module_tags
}

resource "aws_s3_object" "deb-gpg-public-key" {
  bucket       = module.repo_bucket.bucket_name
  key          = "DEB-GPG-KEY-${var.domain_name}"
  content      = join("\n", var.gpg_public_keys)
  content_type = "text/plain"
  tags         = local.default_module_tags
}
