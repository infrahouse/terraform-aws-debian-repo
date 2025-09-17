resource "aws_route53_record" "repo" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.repo.domain_name
    zone_id                = aws_cloudfront_distribution.repo.hosted_zone_id
  }
}

resource "aws_route53_record" "caa_repo" {
  name    = var.domain_name
  type    = "CAA"
  zone_id = var.zone_id
  ttl     = 300
  records = [
    "0 issue \"amazon.com\"",
    "0 issuewild \";\""
  ]
}
