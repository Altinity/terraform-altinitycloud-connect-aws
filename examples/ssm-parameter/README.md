# SSM Parameter

Loads the PEM certificate from AWS SSM Parameter Store instead of a local file.

## Usage

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem_ssm_parameter_name = "/altinity/cloud-connect/pem"
}
```

## Prerequisites

- An [Altinity.Cloud](https://altinity.cloud) account.
- The PEM certificate stored as a SecureString in AWS SSM Parameter Store.
