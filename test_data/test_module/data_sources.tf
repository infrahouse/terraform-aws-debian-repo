data "aws_route53_zone" "cicd" {
  name = var.test_zone
}
