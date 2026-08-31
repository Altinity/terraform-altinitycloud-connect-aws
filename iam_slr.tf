locals {
  service_linked_roles = {
    "elasticloadbalancing.amazonaws.com" = "AWSServiceRoleForElasticLoadBalancing"
    "eks-nodegroup.amazonaws.com"        = "AWSServiceRoleForAmazonEKSNodegroup"
  }

  # Data source returns an empty set when nothing matches, unlike aws_iam_role which errors.
  existing_service_linked_roles = tolist(try(one(data.aws_iam_roles.service_linked).names, []))

  missing_service_linked_roles = var.create_service_linked_roles ? {
    for service, role_name in local.service_linked_roles :
    service => role_name if !contains(local.existing_service_linked_roles, role_name)
  } : {}
}

data "aws_iam_roles" "service_linked" {
  count       = var.create_service_linked_roles ? 1 : 0
  path_prefix = "/aws-service-role/"
}

resource "aws_iam_service_linked_role" "this" {
  for_each         = local.missing_service_linked_roles
  aws_service_name = each.key
  description      = "Service-linked role required by Altinity.Cloud Anywhere"
}
