# Permissions Boundary

Enables IAM permissions boundary with restricted permissions and external S3 bucket access.

## Usage

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

  enable_permissions_boundary = true
  restricted_iam_permissions  = true

  external_buckets = [
    "my-clickhouse-backups",
    "my-data-lake",
  ]
}
```

## Prerequisites

- An [Altinity.Cloud](https://altinity.cloud) account with the [Terraform provider](https://github.com/altinity/terraform-provider-altinitycloud) configured.
- S3 buckets that should be accessible from the cloud-connect environment.
