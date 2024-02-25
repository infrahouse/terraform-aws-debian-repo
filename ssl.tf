resource "aws_acm_certificate" "repo" {
  provider          = aws.ue1
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = local.tags
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.repo.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name    = each.value.name
  type    = each.value.type
  zone_id = var.zone_id
  records = [
    each.value.record
  ]
  ttl = 60
}

resource "aws_acm_certificate_validation" "repo" {
  provider        = aws.ue1
  certificate_arn = aws_acm_certificate.repo.arn
  validation_record_fqdns = [
    aws_route53_record.cert_validation[aws_acm_certificate.repo.domain_name].fqdn
  ]
}
