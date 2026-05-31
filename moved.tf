moved {
  from = aws_s3_bucket.repo
  to   = module.repo_bucket.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_public_access_block.repo
  to   = module.repo_bucket.aws_s3_bucket_public_access_block.public_access
}

moved {
  from = aws_s3_bucket_ownership_controls.repo
  to   = module.repo_bucket.aws_s3_bucket_ownership_controls.this[0]
}

moved {
  from = aws_s3_bucket_acl.repo
  to   = module.repo_bucket.aws_s3_bucket_acl.this[0]
}

moved {
  from = aws_s3_bucket_versioning.repo
  to   = module.repo_bucket.aws_s3_bucket_versioning.enabled[0]
}

moved {
  from = aws_s3_bucket_policy.bucket-access
  to   = module.repo_bucket.aws_s3_bucket_policy.this
}

moved {
  from = aws_s3_bucket.repo-logs
  to   = module.logs_bucket.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_ownership_controls.repo-logs
  to   = module.logs_bucket.aws_s3_bucket_ownership_controls.this[0]
}

moved {
  from = aws_s3_bucket_acl.repo-logs
  to   = module.logs_bucket.aws_s3_bucket_acl.this[0]
}

moved {
  from = aws_s3_bucket_policy.repo-logs
  to   = module.logs_bucket.aws_s3_bucket_policy.this
}
