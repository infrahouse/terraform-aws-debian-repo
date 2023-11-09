resource "aws_cloudfront_distribution" "repo" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]

  origin {
    domain_name = aws_s3_bucket_website_configuration.repo.website_endpoint
    origin_id   = local.origin_id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "https-only"
    allowed_methods = [
      "GET", "HEAD"
    ]
    cached_methods = [
      "GET", "HEAD"
    ]
    cache_policy_id = aws_cloudfront_cache_policy.default.id

    dynamic "function_association" {
      for_each = var.http_auth_user != null ? [{}] : []
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.http_auth.arn
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.repo.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations = [
        "RU",
        "CN",
        "IR"
      ]
    }
  }

  logging_config {
    bucket = aws_s3_bucket.repo-logs.bucket_domain_name
  }

  depends_on = [
    aws_acm_certificate_validation.repo
  ]
}

resource "aws_cloudfront_cache_policy" "default" {
  name        = "${var.bucket_name}_default"
  min_ttl     = 60
  default_ttl = 300
  max_ttl     = 600

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }

}


resource "aws_cloudfront_function" "http_auth" {
  name    = replace("${var.domain_name}-auth", ".", "_")
  runtime = "cloudfront-js-1.0"
  comment = "Enable HTTP basic authentication"
  publish = true

  code = templatefile(
    "${path.module}/handler-http-auth.js.tftpl",
    {
      auth_str = base64encode("${var.http_auth_user != null ? var.http_auth_user : ""}:${var.http_auth_password != null ? var.http_auth_password : ""}")
    }
  )
}
