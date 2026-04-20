locals {
  # Central definition of every Service-Linked Role this module knows about.
  # Both the optional aws_iam_service_linked_role resources below and the
  # "ServiceLinkedRoles" statement in iam_pb.tf derive from this map, so the
  # SLR identifiers live in a single place.
  service_linked_role_definitions = {
    eks = {
      service_name = "eks.amazonaws.com"
      role_name    = "AWSServiceRoleForAmazonEKS"
    }
    "eks-nodegroup" = {
      service_name = "eks-nodegroup.amazonaws.com"
      role_name    = "AWSServiceRoleForAmazonEKSNodegroup"
    }
    elb = {
      service_name = "elasticloadbalancing.amazonaws.com"
      role_name    = "AWSServiceRoleForElasticLoadBalancing"
    }
  }
}

resource "aws_iam_service_linked_role" "this" {
  for_each         = var.create_service_linked_roles ? var.service_linked_roles : toset([])
  aws_service_name = local.service_linked_role_definitions[each.value].service_name

  lifecycle {
    ignore_changes = [aws_service_name]
  }
}
