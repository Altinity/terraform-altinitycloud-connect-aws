# Hardened

Security-focused configuration: IMDSv2 required, restricted IAM permissions, Altinity access disabled, and custom security groups.

## Usage

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

  require_imdsv2             = true
  restricted_iam_permissions = true
  allow_altinity_access      = false

  ec2_security_group_ids = [
    "sg-0123456789abcdef0",
  ]
}
```

## Prerequisites

- An [Altinity.Cloud](https://altinity.cloud) account with the [Terraform provider](https://github.com/altinity/terraform-provider-altinitycloud) configured.
- Pre-existing security group(s) to attach to the EC2 instances.
