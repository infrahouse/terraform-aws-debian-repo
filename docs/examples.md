# Examples

Common use cases for the module.

## Basic Repository (No Authentication)

A public APT repository for open-source packages:

```hcl
module "oss_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-oss-noble"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "packages.example.com"
  replication_region = "us-east-1"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id
}
```

## Private Repository with Authentication

Restrict access with HTTP basic auth:

```hcl
module "private_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-internal-noble"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "internal-packages.example.com"
  replication_region = "us-east-1"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id

  http_auth_user     = "apt-reader"
  http_auth_password = var.apt_password
}
```

## Multiple Codenames (Separate Modules)

One repository per Ubuntu release:

```hcl
module "repo_noble" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-packages-noble"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "noble.packages.example.com"
  replication_region = "us-east-1"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id
}

module "repo_jammy" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-packages-jammy"
  environment         = "production"
  repository_codename = "jammy"
  domain_name         = "jammy.packages.example.com"
  replication_region = "us-east-1"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id
}
```

## CI/CD Integration

Grant a CI/CD role permission to upload packages:

```hcl
module "debian_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-packages-noble"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "packages.example.com"
  replication_region = "us-east-1"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id

  bucket_admin_roles = [
    aws_iam_role.github_actions.arn,
  ]
  signing_key_readers = [
    aws_iam_role.github_actions.arn,
  ]
}
```

Then in your CI pipeline:

```bash
pip install infrahouse-toolkit
ih-s3-reprepro \
  --bucket my-company-packages-noble \
  --gpg-key-secret packager-key-noble \
  --gpg-passphrase-secret packager-passphrase-noble \
  includedeb noble ./my-package_1.0.0_amd64.deb
```

## Multi-Architecture Repository

Serve both amd64 and arm64 packages:

```hcl
module "debian_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-packages-noble"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "packages.example.com"
  replication_region = "us-east-1"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id
  architectures       = ["amd64", "arm64"]
}
```

## Custom Backup Schedule

Weekly backups with 90-day retention:

```hcl
module "debian_repo" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source  = "registry.infrahouse.com/infrahouse/debian-repo/aws"
  version = "4.0.0"

  bucket_name         = "my-company-packages-noble"
  environment         = "production"
  repository_codename = "noble"
  domain_name         = "packages.example.com"
  replication_region = "us-east-1"
  gpg_public_keys     = [
    file("./files/DEB-GPG-KEY-my-company")
  ]
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id

  backup_schedule       = "cron(0 3 ? * SUN *)"
  backup_retention_days = 90
}
```
