# Configuration Reference

This page documents all available configuration options.

## Required Variables

| Variable | Description |
|----------|-------------|
| `bucket_name` | S3 bucket name for the repository |
| `domain_name` | Domain name where the repository will be available |
| `environment` | Environment name (e.g., "production") |
| `gpg_public_keys` | Armored GPG public key(s) to publish; concatenated into one keyring so clients trust a Release signed by any of them |
| `gpg_sign_with` | Signing key identifier(s): a packager email or space-separated GPG key IDs / fingerprints |
| `repository_codename` | Distribution codename (e.g., "noble", "jammy") |
| `zone_id` | Route53 zone ID for the parent domain |

## Providers

The module requires two AWS providers:

```hcl
module "debian_repo" {
  providers = {
    aws     = aws            # Your main region
    aws.ue1 = aws.us-east-1  # Required for CloudFront ACM certificates
  }
  # ...
}
```

## Repository Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `repository_codename` | string | (required) | Ubuntu/Debian codename: focal, jammy, noble, etc. |
| `architectures` | list(string) | `["amd64"]` | CPU architectures served (e.g., amd64, arm64) |
| `package_version_limit` | number | `null` | Max versions per package to keep. null = unlimited. |

## Authentication

HTTP basic authentication is disabled by default. To enable it:

```hcl
module "debian_repo" {
  # ...
  http_auth_user     = "apt-reader"
  http_auth_password = var.http_password
}
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `http_auth_user` | string | `null` | Username. null disables authentication. |
| `http_auth_password` | string | `null` | Password. Required if user is set. |

When enabled, APT clients must include credentials:

```bash
echo "deb [signed-by=/usr/share/keyrings/my.gpg] \
  https://apt-reader:PASSWORD@packages.example.com noble main" \
  > /etc/apt/sources.list.d/my-repo.list
```

## Bucket Administration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bucket_name` | string | (required) | Globally unique S3 bucket name |
| `bucket_admin_roles` | list(string) | `[]` | IAM role ARNs allowed to upload packages |
| `bucket_force_destroy` | bool | `false` | Allow Terraform to destroy non-empty bucket |

Grant your CI/CD role upload access:

```hcl
module "debian_repo" {
  # ...
  bucket_admin_roles = [
    "arn:aws:iam::123456789012:role/ci-packager"
  ]
}
```

## GPG Signing

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `gpg_public_keys` | list(string) | (required) | Armored GPG public keys to publish (concatenated into one keyring bundle) |
| `gpg_sign_with` | string | (required) | Packager email or space-separated GPG key IDs to sign with |
| `signing_key_readers` | list(string) | `null` | Role ARNs that can read the GPG key |
| `signing_key_writers` | list(string) | `null` | Role ARNs that can write/rotate the GPG key |

## Backup

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `backup_schedule` | string | `"cron(0 5 * * ? *)"` | AWS Backup cron expression (default: daily 5 AM UTC) |
| `backup_retention_days` | number | `30` | Days to retain backup recovery points |
| `backup_force_destroy` | bool | `false` | Allow destroying vault with recovery points |

## Customization

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `index_title` | string | `"Debian packages repository"` | HTML title for the index page |
| `index_body` | string | `"Stay tuned!"` | HTML body content for the index page |
| `tags` | map | `{}` | Additional tags to apply to all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `repo_url` | Full HTTPS URL of the repository |
| `release_bucket` | S3 bucket name |
| `release_bucket_arn` | S3 bucket ARN |
| `packager_key_secret_arn` | ARN of the GPG private key secret |
| `packager_key_secret_id` | ID of the GPG private key secret |
| `packager_key_passphrase_secret_arn` | ARN of the passphrase secret |
| `packager_key_passphrase_secret_id` | ID of the passphrase secret |
| `backup_vault_arn` | ARN of the AWS Backup vault |
