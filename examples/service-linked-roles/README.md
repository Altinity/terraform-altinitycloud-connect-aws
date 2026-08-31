# Service-Linked Roles

Creates the AWS service-linked roles required by Altinity.Cloud Anywhere, skipping any that already exist in the account:

- `AWSServiceRoleForElasticLoadBalancing`
- `AWSServiceRoleForAmazonEKSNodegroup`

Both roles are normally created on demand by AWS the first time an ELB or an EKS managed nodegroup is provisioned. Enable this variable when the credentials used at runtime are not allowed to create them, so the environment fails to come up.

## Usage

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

  create_service_linked_roles = true
}
```

## Prerequisites

- An [Altinity.Cloud](https://altinity.cloud) account with the [Terraform provider](https://github.com/altinity/terraform-provider-altinitycloud) configured.
- `iam:ListRoles` and `iam:CreateServiceLinkedRole` on the credentials running Terraform.

## Notes

Service-linked roles are account-global. `terraform destroy` attempts to delete the roles this module created; AWS rejects the deletion while they are still in use by an ELB or an EKS nodegroup.
