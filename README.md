# Terraform Altinity.Cloud AWS Connect Module

<div align="right">
  <img src="https://altinity.com/wp-content/uploads/2022/05/logo_horizontal_blue_white.svg" alt="Altinity" width="120">
</div>

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/altinity/connect-aws/altinitycloud/latest)
[![Latest Version](https://img.shields.io/badge/dynamic/json?label=version&query=$.version&url=https%3A//registry.terraform.io/v1/modules/altinity/connect-aws/altinitycloud)](https://registry.terraform.io/modules/altinity/connect-aws/altinitycloud/latest)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A Terraform module that sets up the necessary AWS infrastructure to connect your AWS account to [Altinity.Cloud](https://altinity.cloud/anywhere). This module provisions EC2 instances running the cloud-connect service, along with the required IAM roles, security groups, and networking components.

If you're looking for a way to manage ClickHouse clusters via Terraform, see [terraform-provider-altinitycloud](https://github.com/altinity/terraform-provider-altinitycloud).

## Prerequisites

Before using this module, ensure you have:

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **Altinity.Cloud account** and access to the cloud-connect certificate

## Usage

### Basic Setup

```terraform
provider "aws" {
  region = "us-west-2"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  # Certificate from `altinitycloud-connect login`
  pem = file("cloud-connect.pem")
}
```

## Examples

### High Availability Setup

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")

  # High availability configuration
  replicas      = 3
  instance_type = "t3.medium"

  # Optional tags
  tags = {
    Environment = "production"
    HA          = "true"
  }
}
```

### Custom VPC Setup

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")

  # Create new VPC with custom CIDR
  cidr_block               = "172.16.0.0/16"
  map_public_ip_on_launch = true

  # Security configuration
  allow_altinity_access = false
  require_imdsv2       = true

  # Optional tags
  tags = {
    Environment = "staging"
    VPC         = "custom"
  }
}
```

### Using Existing VPC

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")

  # Use existing VPC subnets
  subnets = [
    "subnet-12345678",
    "subnet-87654321",
    "subnet-11223344"
  ]

  # Optional tags
  tags = {
    Environment = "production"
    VPC         = "existing"
  }
}
```

## Configuration

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `pem` | Contents of cloud-connect.pem certificate (if not using SSM) | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `pem_ssm_parameter_name` | AWS SSM Parameter containing the certificate | `string` | `""` |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` |
| `replicas` | Number of cloud-connect instances (1-3) | `number` | `1` |
| `subnets` | List of subnet IDs for instances | `list(string)` | `[]` |
| `use_default_subnets` | Use default VPC subnets | `bool` | `false` |
| `cidr_block` | CIDR block for new VPC | `string` | `"10.0.0.0/16"` |
| `allow_altinity_access` | Allow Altinity break-glass access | `bool` | `true` |
| `enable_permissions_boundary` | Enable IAM permission boundaries | `bool` | `false` |
| `external_buckets` | Additional S3 buckets to allow access | `list(string)` | `[]` |
| `restricted_iam_permissions` | Use scoped IAM permissions | `bool` | `false` |
| `tags` | Resource tags | `map(string)` | `{}` |

For a complete list of variables, see [variables.tf](variables.tf).

## Outputs

| Name | Description |
|------|-------------|
| `resource_prefix` | AWS resource prefix (when permission boundary enabled) |
| `permissions_boundary_policy_arn` | ARN of the permission boundary policy |


## Troubleshooting

- **Instance fails to start:** Check certificate validity and network connectivity to Altinity.Cloud. Review CloudWatch logs.
- **Permission errors:** Ensure AWS credentials have sufficient permissions and verify IAM role policies.
- **Network connectivity issues:** Verify subnet routing tables, security group rules, and internet gateway configuration.

### Need Help?

If you encounter issues not covered above, please [create an issue](https://github.com/altinity/terraform-altinitycloud-connect-aws/issues/new) and include:

- **Terraform** and module version
- **Error messages** or logs from CloudWatch/Terraform
- **Configuration details** (sanitized `terraform plan` output)
- **Steps to reproduce** the issue

## Contributing

Contributions are welcome! Please submit a Pull Request or open an issue for major changes. See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and advanced configuration examples.

## License

All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.
Copyright (c) 2023 Altinity, Inc.
