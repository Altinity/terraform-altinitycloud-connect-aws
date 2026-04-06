# Default Subnets

Uses the default VPC subnets instead of creating new ones.

## Usage

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem                 = altinitycloud_env_certificate.this.pem
  use_default_subnets = true
}
```

## Prerequisites

- An [Altinity.Cloud](https://altinity.cloud) account with the [Terraform provider](https://github.com/altinity/terraform-provider-altinitycloud) configured.
- A default VPC with subnets available in the target region.
