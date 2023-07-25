/* debian-repo

The module creates a number of various resources. All of them are grouped together into separate files.

In no particular order:

** cloudfront.tf

- Creates a CloudFront distribution and its cache policy

** bucket.tf

- Creates an S3 bucket for the repository
- Configures HTTP access to the bucket
- Creates a bucket for HTTP access logs
- Creates index.html object
- Creates an object with a GPG public key

** dns.tf

- Creates an A record for the repository in a Route53 zone.

** gpg.tf

- Creates a secret storage for a GPG private key that is used for signing the repository
- Creates a secret storage for the GPG key passphrase
- Creates the passphrase and stores it in the secret

** repo.tf

- Creates a configuration file (conf/distributions) for reprepro as an S3 object

** ssl.tf

- Creates a domain certificate
- Creates DNS validation records
- Validates the certificate

*/