# Existing VPC

Deploys into pre-existing subnets instead of creating a new VPC.

## Usage

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

  subnets = [
    "subnet-aaaa1111",
    "subnet-bbbb2222",
    "subnet-cccc3333",
  ]
}
```

## Prerequisites

- An [Altinity.Cloud](https://altinity.cloud) account with the [Terraform provider](https://github.com/altinity/terraform-provider-altinitycloud) configured.
- An existing VPC with at least one subnet.
