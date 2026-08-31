locals {
  service_linked_roles = {
    "elasticloadbalancing.amazonaws.com" = "AWSServiceRoleForElasticLoadBalancing"
    "eks-nodegroup.amazonaws.com"        = "AWSServiceRoleForAmazonEKSNodegroup"
  }

  # Ownership marker. Service-linked roles are account-global and Terraform cannot read its own
  # state from HCL, so the description is what tells a later plan "this module created this role".
  # Scoped per env, otherwise two envs in the same AWS account both claim the role and collide.
  service_linked_role_description = "Service-linked role created by Altinity.Cloud Anywhere (${local.env_name})"

  # aws_iam_roles returns an empty set when nothing matches, unlike aws_iam_role which fails the plan.
  existing_service_linked_roles = tolist(try(one(data.aws_iam_roles.service_linked).names, []))

  # A role stays in for_each once this module owns it. Deriving membership from live existence alone
  # would drop the key on the next refresh and plan a destroy of the role we just created.
  managed_service_linked_roles = var.create_service_linked_roles ? {
    for service, role_name in local.service_linked_roles :
    service => role_name
    if !contains(local.existing_service_linked_roles, role_name) ||
    try(data.aws_iam_role.service_linked[role_name].description, "") == local.service_linked_role_description
  } : {}
}

data "aws_iam_roles" "service_linked" {
  count       = var.create_service_linked_roles ? 1 : 0
  path_prefix = "/aws-service-role/"
}

data "aws_iam_role" "service_linked" {
  for_each = var.create_service_linked_roles ? toset([
    for role_name in values(local.service_linked_roles) :
    role_name if contains(local.existing_service_linked_roles, role_name)
  ]) : toset([])

  name = each.value
}

resource "aws_iam_service_linked_role" "this" {
  for_each = local.managed_service_linked_roles

  aws_service_name = each.key
  description      = local.service_linked_role_description
}
