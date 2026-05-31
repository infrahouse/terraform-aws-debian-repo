# Getting Started

This guide walks you through deploying your first Debian APT repository.

## Prerequisites

### AWS Resources

1. **Route53 hosted zone** for your domain (e.g., `example.com`)
2. **Two AWS providers** -- default region + `us-east-1` (required for CloudFront ACM certificates)

### GPG Key Pair

You need a GPG key pair for signing packages. If you don't have one:

```bash
gpg --full-gen-key
```

Choose:

- Key type: RSA and RSA
- Key size: 4096 bits
- Validity: 2 years (recommended)
- Name/email: e.g., "My Company Packager" / `packager@example.com`

Export the public key:

```bash
gpg --armor --export packager@example.com > ./files/DEB-GPG-KEY-my-company
```

### Tools

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [infrahouse-toolkit](https://pypi.org/project/infrahouse-toolkit/) (for managing secrets and packages)

## Deployment

### Step 1: Configure Providers

```hcl
provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "aws-us-east-1"
}
```

The `us-east-1` provider is required because CloudFront only accepts ACM certificates
from that region.

### Step 2: Deploy the Module

```hcl
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
  gpg_public_key      = file("./files/DEB-GPG-KEY-my-company")
  gpg_sign_with       = "packager@example.com"
  zone_id             = data.aws_route53_zone.example.id
}
```

```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Upload the GPG Private Key

The module creates a Secrets Manager secret for the GPG private key but leaves it
empty. You need to upload the key.

First, get the generated passphrase:

```bash
ih-secrets --aws-region us-west-1 get packager-passphrase-noble
```

Update the passphrase in your GPG key:

```bash
gpg --edit-key packager@example.com
gpg> passwd
gpg> save
```

Export and upload the private key:

```bash
gpg --armor --export-secret-key packager@example.com > gpg-private-key
ih-secrets --aws-region us-west-1 set packager-key-noble gpg-private-key
rm gpg-private-key
```

### Step 4: Verify

```bash
ih-s3-reprepro --bucket my-company-packages-noble check
```

If the exit code is zero, your repository is ready.

## Configuring APT Clients

On machines that should consume packages from your repository:

```bash
# Download and install the GPG key
curl -fsSL https://packages.example.com/DEB-GPG-KEY-my-company \
  | gpg --dearmor -o /usr/share/keyrings/my-company.gpg

# Add the repository
echo "deb [signed-by=/usr/share/keyrings/my-company.gpg] \
  https://packages.example.com noble main" \
  > /etc/apt/sources.list.d/my-company.list

apt-get update
```

## Next Steps

- [Enable HTTP authentication](configuration.md#authentication) to restrict access
- [Configure backup retention](configuration.md#backup) to meet your compliance needs
- [Grant upload access](configuration.md#bucket-administration) to CI/CD roles
