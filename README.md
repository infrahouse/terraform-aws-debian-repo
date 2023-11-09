# terraform-aws-debian-repo

Module that creates a Debian repository backed by S3 and fronted by CloudFront.
## Usage example

### Step 1. GPG keypair
Create a certificate (if you don't already have it) for signing the repository.
```shell
# gpg --full-gen-key

gpg (GnuPG) 2.2.19; Copyright (C) 2019 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
  (14) Existing key from card
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 2y
Key expires at Wed Jul 23 17:18:31 2025 PDT
Is this correct? (y/N) Y

GnuPG needs to construct a user ID to identify your key.

Real name: InfraHouse Packager
Email address: packager-jammy@infrahouse.com
Comment: key for signing Ubuntu jammy repository
You selected this USER-ID:
    "InfraHouse Packager (key for signing Ubuntu jammy repository) <packager-jammy@infrahouse.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
```
Save a passphrase if you provided one. Or don't provide it at all. We will chnage it later anyway.

Export a public key, save it in a file.

```shell
# gpg --armor --export packager-jammy@infrahouse.com \
    > ./files/DEB-GPG-KEY-infrahouse-jammy
```

### Step 2. AWS resources
Create a 'regular' aws provider.
```hcl
provider "aws" {
  region = "us-west-1"
}
```

[ACM](https://aws.amazon.com/certificate-manager/) requires a certificate to be created in `us-east-1`.
So, we need a provider in `us-east-1`.
```hcl
provider "aws" {
  region = "us-east-1"
  alias = "aws-us-east-1"
}
```

Now, let's create a Debian repo for Ubuntu jammy. It will have address https://release.infrahouse.com
```hcl
module "release_infrahouse_com" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
  source               = "infrahouse/terraform-aws-debian-repo"
  bucket_name          = "infrahouse-release"
  repository_codename  = "jammy"
  domain_name          = "release.infrahouse.com"
  gpg_public_key       = file("./files/DEB-GPG-KEY-infrahouse-jammy")
  gpg_sign_with        = "packager-jammy@infrahouse.com"
  index_title          = "InfraHouse Releases Repository"
  index_body           = "Stay tuned!"
  zone_id              = data.aws_route53_zone.infrahouse_com.id
}
```
> **_NOTE 1:_**  The module creates a secret for the **GPG key**,
> but the secret doesn't have a value. Think about the secret
> as a storage for the GPG key.
> You'll have to upload its content as a secret string in the next step.

> **_NOTE 2:_**  The module however generates a new passphrase and stores
> it in a secret.
> You'll have to fetch it and change it in the private GPG key.

### Step 3. Upload GPG private key

To make the step easier install [infrahouse-toolkit](https://pypi.org/project/infrahouse-toolkit/).

```shell
# pip install infrahouse-toolkit~=1.7
```

Get the generated passphrase.

```shell
# ih-s3-reprepro --aws-region us-west-1 \
    --bucket infrahouse-release \
    get-secret-value packager-passphrase-jammy
```

Update the passphrase in the GPG private key.

```shell
# gpg --edit-key packager-jammy@infrahouse.com

gpg> passwd
gpg> save
```

Export the private GPG key to a file.

```shell

# gpg --armor --export-secret-key packager-jammy@infrahouse.com \
    > gpg-private-key
```

Upload the private GPG key

```shell
# ih-s3-reprepro --aws-region us-west-1 \
    --bucket infrahouse-release \
    secret-value packager-key-jammy gpg-private-key
```
### Step 4. Check the repository

```shell
# ih-s3-reprepro --bucket infrahouse-release-jammy check
Checking jammy...

# echo $?
0
```
If the output looks similar and an exit code is zero - all looks good!

## Authentication

The module supports HTTP basic authentication. By default, it's disabled. To enable it, 
add `http_auth_user` and `http_auth_password` variables.
```hcl
module "release_infrahouse_com" {
  providers = {
    aws     = aws
    aws.ue1 = aws.aws-us-east-1
  }
...

  http_auth_user      = var.http_user
  http_auth_password  = var.http_password
}
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.67 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.67 |
| <a name="provider_aws.ue1"></a> [aws.ue1](#provider\_aws.ue1) | >= 4.67 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_cache_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_distribution.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.http_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_route53_record.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.repo-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.repo-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.repo-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.public-access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_website_configuration.repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_s3_object.deb-gpg-public-key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.distributions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.index-html](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_secretsmanager_secret.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.passphrase](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.passphrase](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.passphrase](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_iam_policy_document.public-access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | If true, the repository bucket will be destroyed even if it contains files. | `bool` | `false` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | S3 bucket name for the repository. | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name where the repository will be available. | `string` | n/a | yes |
| <a name="input_gpg_public_key"></a> [gpg\_public\_key](#input\_gpg\_public\_key) | Content of the GPG public key used for signing the repository. Note, you'll have to upload the key manually or with 'ih-s3-reprepro ... set-secret-value packager-key-focal ~/packager-key-focal' | `any` | n/a | yes |
| <a name="input_gpg_sign_with"></a> [gpg\_sign\_with](#input\_gpg\_sign\_with) | Email of a packager user. | `any` | n/a | yes |
| <a name="input_http_auth_password"></a> [http\_auth\_password](#input\_http\_auth\_password) | Password for HTTP basic authentication. | `string` | `null` | no |
| <a name="input_http_auth_user"></a> [http\_auth\_user](#input\_http\_auth\_user) | Username for HTTP basic authentication. If not specified, the authentication isn't enabled. | `string` | `null` | no |
| <a name="input_index_body"></a> [index\_body](#input\_index\_body) | Content of a body tag in index.html. | `string` | `"Stay tuned!"` | no |
| <a name="input_index_title"></a> [index\_title](#input\_index\_title) | Content of a title tag in index.html. | `string` | `"Debian packages repository"` | no |
| <a name="input_repository_codename"></a> [repository\_codename](#input\_repository\_codename) | Repository codename. Can be focal, jammy, etc. | `string` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Route53 zone id where the parent domain of var.domain\_name is hosted. If var.domain\_name is repo.foo.com, then the value should be zone\_id of foo.com. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_packager_key_passphrase_secret_arn"></a> [packager\_key\_passphrase\_secret\_arn](#output\_packager\_key\_passphrase\_secret\_arn) | ARN of a secret that will store a GPG private key passphrase. |
| <a name="output_packager_key_passphrase_secret_id"></a> [packager\_key\_passphrase\_secret\_id](#output\_packager\_key\_passphrase\_secret\_id) | Identifier of a secret that will store a GPG private key passphrase. |
| <a name="output_packager_key_secret_arn"></a> [packager\_key\_secret\_arn](#output\_packager\_key\_secret\_arn) | ARN of a secret that will store a GPG private key. |
| <a name="output_packager_key_secret_id"></a> [packager\_key\_secret\_id](#output\_packager\_key\_secret\_id) | Identifier of a secret that will store a GPG private key. |
| <a name="output_release_bucket"></a> [release\_bucket](#output\_release\_bucket) | Bucket name that hosts repository files. |
| <a name="output_release_bucket_arn"></a> [release\_bucket\_arn](#output\_release\_bucket\_arn) | Bucket ARN that hosts repository files. |
