# Permissions Boundary: enable IAM permissions boundary with restricted permissions
# and external S3 bucket access.

provider "aws" {
  region = "us-east-1"
}

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
