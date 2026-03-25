# Hardened: IMDSv2 required, restricted IAM, no Altinity access, and custom
# security groups. Suitable for high-security environments.

provider "aws" {
  region = "us-east-1"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")

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
