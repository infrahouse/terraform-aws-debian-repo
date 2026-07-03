provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "aws-us-east-1"
}

data "aws_route53_zone" "example" {
  name = "example.com"
}

module "debian_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "3.2.0"

  bucket_name         = "my-company-packages-noble"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "packages.example.com"
  gpg_public_keys = [
    file("${path.module}/files/DEB-GPG-KEY-example")
  ]
  gpg_sign_with = "packager@example.com"
  zone_id       = data.aws_route53_zone.example.id
}

output "repo_url" {
  value = module.debian_repo.repo_url
}

output "release_bucket" {
  value = module.debian_repo.release_bucket
}
