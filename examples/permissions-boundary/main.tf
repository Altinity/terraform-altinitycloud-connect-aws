# Permissions Boundary: enable IAM permissions boundary with restricted permissions
# and external S3 bucket access.

provider "aws" {
  region = "us-east-1"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")

  enable_permissions_boundary = true
  restricted_iam_permissions  = true

  external_buckets = [
    "my-clickhouse-backups",
    "my-data-lake",
  ]
}
