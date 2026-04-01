output "env_name" {
  value       = local.env_name
  description = "Environment name extracted from the cloud-connect certificate"
}

output "iam_role_arn" {
  value       = aws_iam_role.this.arn
  description = "ARN of the IAM role used by cloud-connect EC2 instance(s)"
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.this.name
  description = "Name of the Auto Scaling Group"
}

output "resource_prefix" {
  value       = var.enable_permissions_boundary ? local.resource_prefix : null
  description = "AWS resource prefix, only set if permission boundary is enabled"
}

output "permissions_boundary_policy_arn" {
  value       = var.enable_permissions_boundary ? one(aws_iam_policy.altinity-permission-boundary).arn : null
  description = "The ARN of the permission boundary policy"
}
