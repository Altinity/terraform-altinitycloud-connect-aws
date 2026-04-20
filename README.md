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

resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem
}
```

## Examples

### High Availability Setup

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

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
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

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
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

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
| `url` | Altinity.Cloud Anywhere base URL | `string` | `"https://anywhere.altinity.cloud"` |
| `image` | Custom Docker image (defaults to `altinity/cloud-connect:$version`) | `string` | `"altinity/cloud-connect:0.133.0"` |
| `pem_ssm_parameter_name` | AWS SSM Parameter containing the certificate | `string` | `""` |
| `ca_crt` | Custom CA certificate to trust for cloud-connect | `string` | `""` |
| `host_aliases` | Host aliases for the EC2 instance(s) | `map(string)` | `{}` |
| `subnets` | List of subnet IDs for instances | `list(string)` | `[]` |
| `use_default_subnets` | Use default VPC subnets | `bool` | `false` |
| `cidr_block` | CIDR block for new VPC | `string` | `"10.0.0.0/16"` |
| `map_public_ip_on_launch` | Associate public IP on launch when creating VPC | `bool` | `true` |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` |
| `root_volume_size` | Size (GiB) of the root EBS volume | `number` | `20` |
| `root_volume_type` | EBS volume type for the root volume | `string` | `"gp3"` |
| `replicas` | Number of cloud-connect instances (1-3) | `number` | `1` |
| `allow_altinity_access` | Allow Altinity break-glass access | `bool` | `true` |
| `break_glass_principal` | IAM principal used for break-glass access | `string` | `"arn:aws:iam::313342380333:role/AnywhereAdmin"` |
| `tags` | Resource tags | `map(string)` | `{}` |
| `ami_name` | Override AMI name used for lookup | `string` | `""` |
| `ami_owners` | AMI owner IDs used during lookup | `list(string)` | `["amazon"]` |
| `ec2_security_group_ids` | Security groups to attach to the instance(s) | `list(string)` | `[]` |
| `enable_permissions_boundary` | Enable IAM permissions boundary | `bool` | `false` |
| `region` | Override AWS region for lookups | `string` | `""` |
| `aws_account_id` | Override AWS account ID for lookups | `string` | `""` |
| `external_buckets` | Additional S3 buckets to allow access | `list(string)` | `[]` |
| `require_imdsv2` | Require IMDSv2 for EC2 instances | `bool` | `false` |
| `restricted_iam_permissions` | Use scoped IAM permissions | `bool` | `false` |
| `create_user_permissions` | Create user permissions for the IAM role | `bool` | `true` |
| `create_service_linked_roles` | Master switch to let the module create AWS Service-Linked Roles (SLRs). When `false`, `service_linked_roles` is ignored. | `bool` | `false` |
| `service_linked_roles` | Subset of SLRs to create when `create_service_linked_roles` is `true`. Accepts any of `["eks", "eks-nodegroup", "elb"]`. SLRs are global per account; drop the ones you already have. | `set(string)` | `["eks", "eks-nodegroup", "elb"]` |

For a complete list of variables, see [variables.tf](variables.tf).

## Outputs

| Name | Description |
|------|-------------|
| `resource_prefix` | AWS resource prefix (when permission boundary enabled) |
| `permissions_boundary_policy_arn` | ARN of the permission boundary policy |


## Troubleshooting

### Instance fails to start

Check certificate validity and network connectivity to Altinity.Cloud, then review the CloudWatch logs of the cloud-connect EC2 instance(s).

### Permission errors

Ensure the AWS credentials used to apply this module have sufficient permissions and verify the IAM role policies attached to `aws_iam_role.this`.

### Missing AWS Service-Linked Roles

```
CreateCluster: InvalidParameterException: EKS Cluster Service-Linked Role could not
be created with cluster role arn:aws:iam::<ACCOUNT>:role/<env>-eks-cluster or cluster
creator identity. Ensure caller has permission to perform `iam:CreateServiceLinkedRole`
action
```

Some AWS services need account-wide Service-Linked Roles (SLRs) that AWS auto-creates the first time the service is used by a sufficiently privileged identity. When `enable_permissions_boundary = true` or `restricted_iam_permissions = true`, that auto-creation can be blocked because the cloud-connect identity is intentionally scoped down. The error above is the most common symptom on EKS, and an analogous one appears on first ELB creation.

You have two ways to fix it:

1. **Pre-create them once** with the AWS CLI (recommended; SLRs are global per account, so this is a one-off):

   ```bash
   aws iam create-service-linked-role --aws-service-name eks.amazonaws.com
   aws iam create-service-linked-role --aws-service-name eks-nodegroup.amazonaws.com
   aws iam create-service-linked-role --aws-service-name elasticloadbalancing.amazonaws.com
   ```

2. **Let Terraform manage them** by enabling the master switch and (optionally) narrowing the list:

   ```terraform
   module "altinitycloud_connect_aws" {
     # ...
     create_service_linked_roles = true
     # service_linked_roles defaults to ["eks", "eks-nodegroup", "elb"]
     # drop the ones already present in your account, e.g.:
     # service_linked_roles = ["eks", "eks-nodegroup"]
   }
   ```

   Existing SLRs will fail with `EntityAlreadyExists` — drop them from `service_linked_roles`, or import them into state:

   ```bash
   terraform import 'module.altinitycloud_connect_aws.aws_iam_service_linked_role.this["eks"]' \
     arn:aws:iam::<ACCOUNT>:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS
   ```

For provider-level troubleshooting (environment provisioning status, API tokens, MFA on destroy, immutable attributes), see the [provider README](https://github.com/altinity/terraform-provider-altinitycloud#troubleshooting).

## Support

If you need help, reach out to us via Slack:

- **Enterprise customers**: Use your organization's dedicated Altinity Slack channel.
- **Community**: Join the [AltinityDB workspace](https://altinitydbworkspace.slack.com/) and post in the **#terraform** channel.
- **GitHub Issues**: [Open an issue](https://github.com/altinity/terraform-altinitycloud-connect-aws/issues/new) to report bugs or request features.

## Contributing

Contributions are welcome! Please submit a Pull Request or open an issue for major changes. See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and setup instructions.

## License

All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.
Copyright (c) 2023 Altinity, Inc.
