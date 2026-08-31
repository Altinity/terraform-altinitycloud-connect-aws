# Service-Linked Roles

Creates the AWS service-linked roles that Altinity.Cloud Anywhere needs:

| Service name | Role |
|--------------|------|
| `elasticloadbalancing.amazonaws.com` | `AWSServiceRoleForElasticLoadBalancing` |
| `eks-nodegroup.amazonaws.com` | `AWSServiceRoleForAmazonEKSNodegroup` |

AWS normally creates both on demand, the first time an ELB or an EKS managed nodegroup is provisioned. List them here when the credentials used at runtime aren't allowed to create them, so the environment fails to come up.

## Usage

```terraform
resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

  service_linked_roles = [
    "elasticloadbalancing.amazonaws.com",
    "eks-nodegroup.amazonaws.com",
  ]
}
```

## Prerequisites

- An [Altinity.Cloud](https://altinity.cloud) account with the [Terraform provider](https://github.com/altinity/terraform-provider-altinitycloud) configured.
- `iam:CreateServiceLinkedRole` on the credentials running Terraform.

## List only the roles that are missing

Service-linked roles are account-global, and creating one that already exists fails with `EntityAlreadyExists`. Check before listing a role here:

```shell
aws iam get-role --role-name AWSServiceRoleForElasticLoadBalancing
aws iam get-role --role-name AWSServiceRoleForAmazonEKSNodegroup
```

Any that already exist should be left out of `service_linked_roles`; nothing else is needed for them. To bring an existing role under management instead, import it:

```shell
terraform import 'module.altinitycloud_connect_aws.aws_iam_service_linked_role.this["elasticloadbalancing.amazonaws.com"]' \
  arn:aws:iam::123456789012:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing
```

## Notes

The module manages exactly the services listed in `service_linked_roles` and nothing else, so `terraform destroy` deletes only the roles that were explicitly opted into. AWS rejects the deletion while a role is still in use by an ELB or an EKS nodegroup.
