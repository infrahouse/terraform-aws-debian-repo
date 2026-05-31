# Troubleshooting

Common issues and their solutions.

## Certificate Validation Stuck

### Symptoms

`terraform apply` hangs at `aws_acm_certificate_validation.repo` for more than 5 minutes.

### Cause

DNS validation records are not resolving. This usually means the `zone_id` is wrong.

### Fix

1. Verify the zone ID matches the parent domain:

    ```bash
    # If domain_name is "packages.example.com", zone_id should be for "example.com"
    aws route53 list-hosted-zones --query "HostedZones[?Name=='example.com.'].Id"
    ```

2. Check that the CNAME validation records were created:

    ```bash
    aws route53 list-resource-record-sets \
      --hosted-zone-id YOUR_ZONE_ID \
      --query "ResourceRecordSets[?Type=='CNAME']"
    ```

3. Verify DNS propagation:

    ```bash
    dig _acme-challenge.packages.example.com CNAME
    ```

## 403 Forbidden from CloudFront

### Symptoms

`apt-get update` returns a 403 error when accessing the repository.

### Check 1: Object Exists in S3

```bash
aws s3 ls s3://YOUR-BUCKET/dists/noble/main/binary-amd64/Packages.gz
```

If the object doesn't exist, packages haven't been uploaded yet.

### Check 2: Bucket Policy

The bucket policy must allow CloudFront OAC access. Run `terraform plan` to check
for drift.

### Check 3: Authentication Credentials

If HTTP basic auth is enabled, verify the client is sending credentials:

```bash
curl -u "user:password" https://packages.example.com/dists/noble/Release
```

## GPG Signature Verification Failed

### Symptoms

```
W: GPG error: https://packages.example.com noble Release:
The following signatures couldn't be verified because the public key is not available
```

### Fix

1. Ensure the client has the correct GPG key installed:

    ```bash
    curl -fsSL https://packages.example.com/DEB-GPG-KEY-my-company \
      | gpg --dearmor -o /usr/share/keyrings/my-company.gpg
    ```

2. Ensure the sources.list entry references the keyring:

    ```
    deb [signed-by=/usr/share/keyrings/my-company.gpg] \
      https://packages.example.com noble main
    ```

3. Verify the GPG key in the bucket matches the one used for signing:

    ```bash
    aws s3 cp s3://YOUR-BUCKET/DEB-GPG-KEY-my-company - | gpg --show-keys
    ```

## ih-s3-reprepro Fails to Sign Packages

### Symptoms

```
Error: Could not read GPG key from secret
```

### Fix

1. Verify the secret exists and has a value:

    ```bash
    ih-secrets --aws-region us-west-1 get packager-key-noble | head -3
    ```

2. Verify the passphrase matches the key:

    ```bash
    ih-secrets --aws-region us-west-1 get packager-passphrase-noble
    ```

3. Verify IAM permissions -- the role running `ih-s3-reprepro` must be in
   `signing_key_readers`.

## Stale Packages After Upload

### Symptoms

New package version was uploaded but `apt-get update` still shows the old version.

### Cause

CloudFront cache has not expired. Default TTL is 300 seconds (5 minutes).

### Fix

Wait for the cache to expire (up to 10 minutes for max_ttl), or create a
CloudFront invalidation:

```bash
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Aliases.Items[0]=='packages.example.com'].Id" \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/dists/*"
```

## Terraform Destroy Fails

### Symptoms

```
Error: error deleting S3 Bucket: BucketNotEmpty
```

### Fix

Set `bucket_force_destroy = true` in the module call, apply, then destroy:

```hcl
module "debian_repo" {
  # ...
  bucket_force_destroy = true
}
```

```bash
terraform apply
terraform destroy
```

For the backup vault:

```hcl
module "debian_repo" {
  # ...
  backup_force_destroy = true
}
```

## CloudFront Distribution Stuck Deploying

### Symptoms

`terraform apply` hangs at the CloudFront distribution for 15+ minutes.

### Cause

CloudFront deployments take 5-15 minutes to propagate globally. This is normal
for initial creation.

### Fix

Wait. If it exceeds 30 minutes, check the AWS Console for the distribution status.
Rarely, a distribution can get stuck -- in that case, contact AWS Support.

## Getting Help

If your issue is not covered here:

1. Check [CloudFront access logs](architecture.md#cloudfront-delivery) for request details
2. Review [AWS CloudFront troubleshooting documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/troubleshooting-distributions.html)
3. [Open an issue](https://github.com/infrahouse/terraform-aws-debian-repo/issues/new)
   with:
    - Module version
    - Terraform plan/apply output
    - Relevant log entries
