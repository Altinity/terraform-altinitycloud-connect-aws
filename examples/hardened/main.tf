# Hardened: IMDSv2 required, restricted IAM, no Altinity access, and custom
# security groups. Suitable for high-security environments.

provider "aws" {
  region = "us-east-1"
}

resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3"

  pem = altinitycloud_env_certificate.this.pem

  require_imdsv2             = true
  restricted_iam_permissions = true
  allow_altinity_access      = false

  ec2_security_group_ids = [
    "sg-0123456789abcdef0",
  ]

  tags = {
    Environment = "production"
    Security    = "hardened"
  }
}
