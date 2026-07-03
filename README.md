# terraform-aws-debian-repo

[![Need Help?](https://img.shields.io/badge/Need%20Help%3F-Contact%20Us-0066CC)](https://infrahouse.com/contact)
[![Docs](https://img.shields.io/badge/docs-github.io-blue)](https://infrahouse.github.io/terraform-aws-debian-repo/)
[![Registry](https://img.shields.io/badge/Terraform-Registry-purple?logo=terraform)](https://registry.terraform.io/modules/infrahouse/debian-repo/aws/latest)
[![Release](https://img.shields.io/github/release/infrahouse/terraform-aws-debian-repo.svg)](https://github.com/infrahouse/terraform-aws-debian-repo/releases/latest)
[![AWS S3](https://img.shields.io/badge/AWS-S3-orange?logo=amazons3)](https://aws.amazon.com/s3/)
[![AWS CloudFront](https://img.shields.io/badge/AWS-CloudFront-orange?logo=amazonaws)](https://aws.amazon.com/cloudfront/)
[![Security](https://img.shields.io/github/actions/workflow/status/infrahouse/terraform-aws-debian-repo/vuln-scanner-pr.yml?label=Security)](https://github.com/infrahouse/terraform-aws-debian-repo/actions/workflows/vuln-scanner-pr.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

A Terraform module that creates a private Debian APT package repository backed by S3
and fronted by CloudFront. It manages GPG key secrets, ACM certificates, Route53 DNS,
optional HTTP basic authentication, and automated S3 backups.

## Why This Module?

Running your own APT repository gives you full control over package distribution
for your infrastructure. However, setting one up on AWS involves orchestrating many
services (S3, CloudFront, ACM, Route53, Secrets Manager, Backup). This module handles
all of that in a single, tested, production-ready package:

- **No servers to manage** -- S3 + CloudFront means zero operational overhead
- **HTTPS by default** -- ACM certificate with automated DNS validation
- **GPG signing built-in** -- Secrets Manager stores keys securely with IAM-based access control
- **Geo-restricted** -- Blocks traffic from high-risk regions by default
- **Backed up** -- AWS Backup protects against accidental deletion
- **Compatible with standard tools** -- Works with `reprepro`, `apt-get`, and `ih-s3-reprepro`

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
provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "aws-us-east-1"
}

module "debian_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-packages"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "packages.example.com"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id
}
```

## Documentation

- [Getting Started](https://infrahouse.github.io/terraform-aws-debian-repo/getting-started/) -- Prerequisites and first deployment
- [Architecture](https://infrahouse.github.io/terraform-aws-debian-repo/architecture/) -- How the module works
- [Configuration](https://infrahouse.github.io/terraform-aws-debian-repo/configuration/) -- All available options
- [Examples](https://infrahouse.github.io/terraform-aws-debian-repo/examples/) -- Common use cases
- [Troubleshooting](https://infrahouse.github.io/terraform-aws-debian-repo/troubleshooting/) -- Common issues and solutions

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the Apache License 2.0 -- see [LICENSE](LICENSE) for details.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.67, < 7.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.67, < 7.0 |
| <a name="provider_aws.ue1"></a> [aws.ue1](#provider\_aws.ue1) | >= 4.67, < 7.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backup_key"></a> [backup\_key](#module\_backup\_key) | registry.infrahouse.com/infrahouse/key/aws | 0.3.0 |
| <a name="module_key"></a> [key](#module\_key) | registry.infrahouse.com/infrahouse/secret/aws | 1.1.1 |
| <a name="module_logs_bucket"></a> [logs\_bucket](#module\_logs\_bucket) | registry.infrahouse.com/infrahouse/s3-bucket/aws | 0.6.0 |
| <a name="module_passphrase"></a> [passphrase](#module\_passphrase) | registry.infrahouse.com/infrahouse/secret/aws | 1.1.1 |
| <a name="module_repo_bucket"></a> [repo\_bucket](#module\_repo\_bucket) | registry.infrahouse.com/infrahouse/s3-bucket/aws | 0.6.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_backup_plan.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_cloudfront_cache_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_distribution.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.http_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.repo-storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_iam_role.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.backup_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.restore_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_record.caa_repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket_logging.server-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_object.deb-gpg-public-key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.distributions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.index-html](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [random_password.passphrase](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_iam_policy_document.backup_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bucket-access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bucket-admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bucket-cloudfront-access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architectures"></a> [architectures](#input\_architectures) | List of architectures served by the repo | `list(string)` | <pre>[<br/>  "amd64"<br/>]</pre> | no |
| <a name="input_backup_force_destroy"></a> [backup\_force\_destroy](#input\_backup\_force\_destroy) | If true, the backup vault will be destroyed even if it contains recovery points. | `bool` | `false` | no |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Number of days to retain S3 backups. | `number` | `30` | no |
| <a name="input_backup_schedule"></a> [backup\_schedule](#input\_backup\_schedule) | Cron expression for the backup schedule in AWS Backup format.<br/>Default is daily at 5:00 AM UTC. | `string` | `"cron(0 5 * * ? *)"` | no |
| <a name="input_bucket_admin_roles"></a> [bucket\_admin\_roles](#input\_bucket\_admin\_roles) | List of AWS IAM role ARN that has permissions to upload to the bucket | `list(string)` | `[]` | no |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | If true, the repository bucket will be destroyed even if it contains files. | `bool` | `false` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | S3 bucket name for the repository. | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name where the repository will be available. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., development, staging, production). Used for resource tagging and identification. | `string` | n/a | yes |
| <a name="input_gpg_public_keys"></a> [gpg\_public\_keys](#input\_gpg\_public\_keys) | Armored GPG public keys to publish for repository verification. They are concatenated into the<br/>single published key object (DEB-GPG-KEY-<domain\_name>); apt trusts a Release signed by any key<br/>in the resulting keyring. During a signing-key rotation this holds both the outgoing and<br/>incoming keys so clients trust a Release signed by either. Each list element is a full armored<br/>public key block.<br/><br/>The private signing key(s) are uploaded out-of-band with<br/>'ih-secrets set packager-key-<codename> ~/packager-key-<codename>'. | `list(string)` | n/a | yes |
| <a name="input_gpg_sign_with"></a> [gpg\_sign\_with](#input\_gpg\_sign\_with) | Signing key identifier(s) for reprepro's SignWith in conf/distributions. Accepts a packager<br/>email or one or more space-separated GPG key IDs / fingerprints. During a key rotation, set this<br/>to both the outgoing and incoming key IDs to dual-sign the repository. | `string` | n/a | yes |
| <a name="input_http_auth_password"></a> [http\_auth\_password](#input\_http\_auth\_password) | Password for HTTP basic authentication. | `string` | `null` | no |
| <a name="input_http_auth_user"></a> [http\_auth\_user](#input\_http\_auth\_user) | Username for HTTP basic authentication. If not specified, the authentication isn't enabled. | `string` | `null` | no |
| <a name="input_index_body"></a> [index\_body](#input\_index\_body) | Content of a body tag in index.html. | `string` | `"Stay tuned!"` | no |
| <a name="input_index_title"></a> [index\_title](#input\_index\_title) | Content of a title tag in index.html. | `string` | `"Debian packages repository"` | no |
| <a name="input_package_version_limit"></a> [package\_version\_limit](#input\_package\_version\_limit) | Number of versions of a package to keep in the repository. Zero means keep all versions. | `number` | `null` | no |
| <a name="input_replication_region"></a> [replication\_region](#input\_replication\_region) | AWS region for the S3 cross-region replication replica buckets. | `string` | n/a | yes |
| <a name="input_repository_codename"></a> [repository\_codename](#input\_repository\_codename) | Repository codename. Can be focal, jammy, etc. | `string` | n/a | yes |
| <a name="input_signing_key_readers"></a> [signing\_key\_readers](#input\_signing\_key\_readers) | List of role ARNs that have permission to read GPG signing key and passphrase. | `list(string)` | `null` | no |
| <a name="input_signing_key_writers"></a> [signing\_key\_writers](#input\_signing\_key\_writers) | List of role ARNs that have permission to write to GPG signing key and passphrase secrets. | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to resources. | `map` | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Route53 zone id where the parent domain of var.domain\_name is hosted. If var.domain\_name is repo.foo.com, then the value should be zone\_id of foo.com. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_vault_arn"></a> [backup\_vault\_arn](#output\_backup\_vault\_arn) | ARN of the AWS Backup vault for the repository bucket. |
| <a name="output_packager_key_passphrase_secret_arn"></a> [packager\_key\_passphrase\_secret\_arn](#output\_packager\_key\_passphrase\_secret\_arn) | ARN of a secret that will store a GPG private key passphrase. |
| <a name="output_packager_key_passphrase_secret_id"></a> [packager\_key\_passphrase\_secret\_id](#output\_packager\_key\_passphrase\_secret\_id) | Identifier of a secret that will store a GPG private key passphrase. |
| <a name="output_packager_key_secret_arn"></a> [packager\_key\_secret\_arn](#output\_packager\_key\_secret\_arn) | ARN of a secret that will store a GPG private key. |
| <a name="output_packager_key_secret_id"></a> [packager\_key\_secret\_id](#output\_packager\_key\_secret\_id) | Identifier of a secret that will store a GPG private key. |
| <a name="output_release_bucket"></a> [release\_bucket](#output\_release\_bucket) | Bucket name that hosts repository files. |
| <a name="output_release_bucket_arn"></a> [release\_bucket\_arn](#output\_release\_bucket\_arn) | Bucket ARN that hosts repository files. |
| <a name="output_repo_url"></a> [repo\_url](#output\_repo\_url) | Repository URL. |
<!-- END_TF_DOCS -->
