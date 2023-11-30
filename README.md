# terraform-altinitycloud-connect-aws

Terraform module for connecting your AWS account to [Altinity.Cloud](https://altinity.cloud/anywhere).  
If you're looking for a way to manage ClickHouse clusters via Terraform,
see [terraform-provider-altinitycloud](https://github.com/altinity/terraform-provider-altinitycloud).

```terraform
provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "0.1.0"
  
  # cloud-connect.pem is produced by `altinitycloud-connect login`.
  # See https://github.com/altinity/altinitycloud-connect for details.
  pem = file("cloud-connect.pem")
}
```

## Legal

All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.  
Copyright (c) 2023 Altinity, Inc.
