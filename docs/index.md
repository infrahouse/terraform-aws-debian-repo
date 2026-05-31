# InfraHouse Debian Repo

This Terraform module creates a private Debian APT package repository backed by S3
and fronted by CloudFront.

## Why This Module?

Setting up an APT repository on AWS requires coordinating S3, CloudFront, ACM,
Route53, Secrets Manager, and Backup. This module handles all of that:

| Concern | How It's Handled |
|---------|-----------------|
| **Storage** | S3 with versioning, public access blocked, SSL-only policy |
| **Delivery** | CloudFront with TLS 1.2+, geo-restriction, caching |
| **DNS** | Route53 A record + CAA record for certificate authority |
| **TLS** | ACM certificate with automated DNS validation |
| **Signing** | GPG key and passphrase in Secrets Manager with IAM access control |
| **Auth** | Optional HTTP basic authentication via CloudFront Function |
| **Backup** | AWS Backup with configurable schedule and retention |

## Features

- S3 bucket for package storage with versioning enabled
- CloudFront distribution with HTTPS-only access and TLS 1.2+
- ACM certificate with automated Route53 DNS validation
- GPG private key and passphrase stored in AWS Secrets Manager
- Optional HTTP basic authentication via CloudFront Function
- Geo-restriction (blocks RU, CN, IR by default)
- CloudFront access logging to a dedicated S3 bucket
- AWS Backup with configurable schedule and retention
- reprepro `conf/distributions` configuration managed as S3 object
- CAA DNS record for certificate authority authorization

## Quick Start

```hcl
module "debian_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "3.2.0"

  bucket_name         = "my-company-packages"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "packages.example.com"
  gpg_public_key      = file("./files/DEB-GPG-KEY-my-company")
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id
}
```

## Documentation

- [Getting Started](getting-started.md) -- Prerequisites and first deployment
- [Architecture](architecture.md) -- How the module works
- [Configuration](configuration.md) -- All available options
- [Examples](examples.md) -- Common use cases
- [Troubleshooting](troubleshooting.md) -- Common issues and solutions
