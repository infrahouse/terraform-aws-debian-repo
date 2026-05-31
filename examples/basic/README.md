# Basic Example

This example creates a Debian APT repository for Ubuntu Noble (24.04).

## Prerequisites

- A Route53 hosted zone for your domain
- A GPG public key file at `files/DEB-GPG-KEY-example`

## Usage

```bash
terraform init
terraform plan
terraform apply
```

After apply, follow the [Getting Started guide](https://infrahouse.github.io/terraform-aws-debian-repo/getting-started/#step-3-upload-the-gpg-private-key)
to upload the GPG private key.
