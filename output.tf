output "resource_prefix" {
  value       = var.enable_permissions_boundary ? local.resource_prefix : null
  description = "AWS resource prefix, only set if permission boundary is enabled"
}

output "permissions_boundary_policy_arn" {
  value       = var.enable_permissions_boundary ? one(aws_iam_policy.altinity-permission-boundary).arn : null
  description = "The ARN of the permission boundary policy"
}
