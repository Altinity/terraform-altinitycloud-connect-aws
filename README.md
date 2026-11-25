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
2. **Terraform** >= 1.2
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
  version = "~> 0.4.0"

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
  version = "~> 0.4.0"

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
  version = "~> 0.4.0"

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

### Private Subnets with NAT Gateway

Launches cloud-connect without public IPs and routes outbound traffic through NAT gateway(s). Requires the VPC to be created by this module.

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.4.0"

  pem = altinitycloud_env_certificate.this.pem

  enable_nat_gateway = true

  # optional: use existing Elastic IPs (e.g. already allowlisted), one NAT gateway per ID
  # nat_eip_allocation_ids = ["eipalloc-0123456789abcdef0"]
}

output "cloud_connect_egress_ips" {
  value = module.altinitycloud_connect_aws.nat_public_ips
}
```

### Using Existing VPC

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.4.0"

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
| `image` | Custom Docker image (defaults to `altinity/cloud-connect:$version`) | `string` | `"altinity/cloud-connect:0.172.4"` |
| `pem_ssm_parameter_name` | AWS SSM Parameter containing the certificate | `string` | `""` |
| `ca_crt` | Custom CA certificate to trust for cloud-connect | `string` | `""` |
| `host_aliases` | Host aliases for the EC2 instance(s) | `map(string)` | `{}` |
| `subnets` | List of subnet IDs for instances | `list(string)` | `[]` |
| `use_default_subnets` | Use default VPC subnets | `bool` | `false` |
| `cidr_block` | CIDR block for new VPC | `string` | `"10.0.0.0/16"` |
| `map_public_ip_on_launch` | Associate public IP on launch (ignored when `enable_nat_gateway` is true) | `bool` | `true` |
| `enable_nat_gateway` | Route outbound traffic through NAT gateway(s) (requires the module-created VPC and a `cidr_block` of /24 or larger) | `bool` | `false` |
| `nat_gateway_count` | Number of NAT gateways, one per availability zone (capped at the number of subnets) | `number` | `1` |
| `nat_eip_allocation_ids` | Existing Elastic IP allocation IDs, one NAT gateway per ID, no more than the number of subnets (allocates new ones if empty) | `list(string)` | `[]` |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` |
| `root_volume_size` | Size (GiB) of the root EBS volume | `number` | `20` |
| `root_volume_type` | EBS volume type for the root volume | `string` | `"gp3"` |
| `replicas` | Number of cloud-connect instances (1-3) | `number` | `1` |
| `heartbeat_timeout` | Maximum time (in seconds) for the ASG launch lifecycle hook to complete before the instance is abandoned | `number` | `420` |
| `allow_altinity_access` | Allow Altinity break-glass access | `bool` | `true` |
| `break_glass_principal` | IAM principal used for break-glass access | `string` | `"arn:aws:iam::313342380333:role/AnywhereAdmin"` |
| `tags` | Resource tags | `map(string)` | `{}` |
| `ami_name` | Override AMI name used for lookup | `string` | `""` |
| `ami_owners` | AMI owner IDs used during lookup | `list(string)` | `["amazon"]` |
| `ec2_security_group_ids` | Security groups to attach to the instance(s) | `list(string)` | `[]` |
| `enable_permissions_boundary` | Enable IAM permissions boundary | `bool` | `false` |
| `region` | Override AWS region for lookups | `string` | `""` |
| `aws_account_id` | Override AWS account ID for lookups | `string` | `""` |
| `external_buckets` | Additional S3 buckets to allow access. Wildcards are supported (e.g. `my-prefix-*`) | `list(string)` | `[]` |
| `require_imdsv2` | Require IMDSv2 for EC2 instances | `bool` | `false` |
| `imds_hop_limit` | IMDSv2 PUT response hop limit for EC2 instances (1-64). If `null`, the account-level IMDS default or the AMI default applies | `number` | `null` |
| `restricted_iam_permissions` | Use scoped IAM permissions | `bool` | `false` |
| `create_user_permissions` | Create user permissions for the IAM role | `bool` | `true` |

For a complete list of variables, see [variables.tf](variables.tf).

### Permissions Boundary Prerequisites

With `enable_permissions_boundary = true`, AWS cannot always create service-linked roles on demand. The first node group, for example, fails with `missing permissions for iam:GetRole` on `AWSServiceRoleForAmazonEKSNodegroup`. Create the roles once per account before creating the environment:

```sh
aws iam create-service-linked-role --aws-service-name eks.amazonaws.com
aws iam create-service-linked-role --aws-service-name eks-nodegroup.amazonaws.com
aws iam create-service-linked-role --aws-service-name elasticloadbalancing.amazonaws.com
```

A "has been taken" error means the role already exists, as it does in accounts that have run EKS before.

### Permissions Boundary Size Limit

AWS caps managed policies at 6144 characters and a role can only have one permissions boundary, so the policy cannot be split. Each entry in `external_buckets` adds two ARNs to it. If the limit is reached, replace individual buckets with a wildcard pattern:

```hcl
external_buckets = ["my-prefix-*"]
```

A pattern allows access to every bucket that matches it, so keep it as narrow as possible.

## Outputs

| Name | Description |
|------|-------------|
| `resource_prefix` | AWS resource prefix (when permission boundary enabled) |
| `permissions_boundary_policy_arn` | ARN of the permission boundary policy |
| `nat_public_ips` | Public IPs of the NAT gateway(s) (when `enable_nat_gateway` is true) |

## Troubleshooting

### Instance fails to start

Check certificate validity and network connectivity to Altinity.Cloud. If instances terminate shortly after launch, use the sections below to capture bootstrap logs before the Auto Scaling group replaces them.

### Get logs

**From a recently terminated instance (console output):**

```bash
aws ec2 get-console-output --instance-id <instance-id> --latest \
  --query Output --output text | tail -100
```

**From a running instance (SSM):**

```bash
sudo tail -100 /var/log/cloud-init-output.log
sudo tail -100 /var/log/cloud-init.log
sudo docker ps -a
sudo docker logs altinitycloud-connect
```

### Increase lifecycle hook timeout

Set `heartbeat_timeout` (seconds) when applying the module — requires version `>= 0.3.3`:

```terraform
module "altinitycloud_connect_aws" {
  # ...
  heartbeat_timeout = 7200
}
```

This extends how long the ASG waits for the launch hook to complete before abandoning an instance that never calls `complete-lifecycle-action`.

### When user-data fails early

If the user-data script exits with a non-zero status, an `EXIT` trap calls `complete-lifecycle-action ABANDON` and the instance terminates within about a minute. In that case, raising `heartbeat_timeout` does not help — the instance is abandoned by the script, not by the hook timing out.

To inspect a failed bootstrap:

1. **Standalone instance (recommended)** — see below. The ASG will not terminate it, so you can use SSM even after user-data fails.

2. **Console output** — run `get-console-output` on the most recently terminated instance (see [Get logs](#get-logs)).

3. **Pause the ASG loop** — suspend scaling processes while debugging an ASG-launched instance:

```bash
aws autoscaling suspend-processes \
  --auto-scaling-group-name <asg-name> \
  --scaling-processes Launch Terminate
```

Suspending `Terminate` can keep a failed instance running long enough to connect via SSM. Resume when finished:

```bash
aws autoscaling resume-processes \
  --auto-scaling-group-name <asg-name> \
  --scaling-processes Launch Terminate
```

### Debug with a standalone instance

Launch an EC2 instance from the same Launch Template **outside** the ASG. It runs the same user-data but won't be terminated by the ASG:

```bash
aws ec2 run-instances \
  --launch-template "LaunchTemplateId=<lt-id>,Version=\$Latest" \
  --subnet-id "<subnet-id>" \
  --count 1
```

Connect via SSM and run the log commands above. On a standalone instance, `complete-lifecycle-action` fails at the end of user-data — that is expected; check the earlier lines in `cloud-init-output.log`.

### Permission errors

Ensure the AWS credentials used to apply this module have sufficient permissions and verify the IAM role policies attached to `aws_iam_role.this`. When `enable_permissions_boundary` is true, the instance role also needs `autoscaling:CompleteLifecycleAction` on the ASG (scoped by the `altinity:cloud/env` tag) and `ssm:GetParameter` on the PEM parameter. For `missing permissions for iam:GetRole` on a service-linked role, see [Permissions Boundary Prerequisites](#permissions-boundary-prerequisites).

## Support

If you need help, reach out to us via Slack:

- **Enterprise customers**: Use your organization's dedicated Altinity Slack channel.
- **Community**: Join the [AltinityDB workspace](https://altinitydbworkspace.slack.com/) and post in the **#terraform** channel.
- **GitHub Issues**: [Open an issue](https://github.com/altinity/terraform-altinitycloud-connect-aws/issues/new) to report bugs or request features.

## Contributing

Contributions are welcome! Please submit a Pull Request or open an issue for major changes. See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and advanced configuration examples.

## License

All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.
Copyright (c) 2023 Altinity, Inc.
