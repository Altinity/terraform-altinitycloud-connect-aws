data "aws_iam_policy_document" "permissions-boundary-policy" {
  count = var.enable_permissions_boundary ? 1 : 0

  statement {
    sid = "Read"
    actions = [
      "ec2:Describe*",
      "autoscaling:Describe*",
      "elasticloadbalancing:Describe*",
      "route53:ListHostedZonesByVPC",
      "sqs:ListQueues"
    ]
    resources = ["*"]
  }

  statement {
    sid = "SSM"
    actions = [
      "ssmmessages:*",
    ]
    resources = ["*"]
  }

  statement {
    sid = "RequireRequestTag"
    actions = [
      "ec2:*",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [local.env_name]
      variable = "aws:RequestTag/altinity:cloud/env"
    }
  }

  statement {
    sid    = "DenyTagsChangeOnNonEnvResources"
    effect = "Deny"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringNotEquals"
      values   = [local.env_name]
      variable = "aws:ResourceTag/altinity:cloud/env"
    }
  }

  statement {
    sid = "AllowTagsDuringCreation"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "ec2:CreateAction"
      values   = ["false"]
    }
  }

  statement {
    sid = "AllowActionsOnEnvResources"
    actions = [
      "ssm:*",
      "ec2:*",
      "eks:*",
      "iam:*",
      "lambda:*",
      "autoscaling:*",
      "elasticloadbalancing:*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [local.env_name]
      variable = "aws:ResourceTag/altinity:cloud/env"
    }
  }

  statement {
    sid = "VPCEndpointServiceMultiRegion"
    actions = [
      "vpce:AllowMultiRegion"
    ]
    resources = ["*"]
  }

  # AcceptVpcPeeringConnection doesn't support RequestTag; scope by accepter VPC instead
  statement {
    sid = "AcceptVPCPeering"
    actions = [
      "ec2:AcceptVpcPeeringConnection",
      "ec2:RejectVpcPeeringConnection",
      "ec2:ModifyVpcPeeringConnectionOptions",
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "ec2:AccepterVpc"
      values   = ["arn:aws:ec2:${local.region}:${local.account_id}:vpc/*"]
    }
  }

  statement {
    sid = "EKS"
    actions = [
      "eks:*",
      "eks-auth:*",
    ]
    resources = [
      "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.resource_prefix}",
      "arn:aws:eks:${local.region}:${local.account_id}:access-entry/${local.resource_prefix}/*",
      "arn:aws:eks:${local.region}:${local.account_id}:nodegroup/${local.resource_prefix}/*",
    ]
  }

  statement {
    sid = "EKSNodePoolsAMIs"
    actions = [
      "ec2:RunInstances"
    ]
    resources = ["arn:aws:ec2:${local.region}::image/ami-*"]
  }

  statement {
    sid = "ECR"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  statement {
    sid = "EKSOIDC"
    actions = [
      "iam:Get*",
    ]
    resources = ["arn:aws:iam::${local.account_id}:oidc-provider/oidc.eks.${local.region}.amazonaws.com/id/*"]
  }

  statement {
    sid = "EKSASG"
    actions = [
      "autoscaling:*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [local.resource_prefix]
      variable = "aws:ResourceTag/eks:cluster-name"
    }
  }

  statement {
    sid = "EKSTag"
    actions = [
      "ec2:CreateTags"
    ]
    resources = ["arn:aws:ec2:${local.region}:${local.account_id}:security-group/*"]
    condition {
      test     = "StringEquals"
      values   = [local.resource_prefix]
      variable = "aws:ResourceTag/aws:eks:cluster-name"
    }
  }

  statement {
    sid = "ServiceLinkedRoles"
    actions = [
      "iam:GetRole",
      "iam:CreateServiceLinkedRole",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS*",
      "arn:aws:iam::${local.account_id}:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup*",
      "arn:aws:iam::${local.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing*",
    ]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:AWSServiceName"
      values = [
        "eks.amazonaws.com",
        "eks-nodegroup.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
      ]
    }
  }

  statement {
    sid = "S3"
    actions = [
      "s3:*",
    ]
    resources = ["arn:aws:s3:::${local.resource_prefix}*"]
  }

  statement {
    sid = "SQS"
    actions = [
      "sqs:*"
    ]
    resources = ["arn:aws:sqs:${local.region}:${local.account_id}:${local.resource_prefix}*"]
  }

  dynamic "statement" {
    for_each = length(var.external_buckets) > 0 ? [1] : []
    content {
      sid = "ExternalBuckets"
      actions = [
        "s3:*",
      ]
      resources = concat(
        [for bucket in var.external_buckets : "arn:aws:s3:::${bucket}"],
        [for bucket in var.external_buckets : "arn:aws:s3:::${bucket}/*"]
      )
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalType"
        values = [
          "AssumedRole"
        ]
      }

      condition {
        test = "ArnLike"
        values = [
          "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}*",
        ]
        variable = "aws:PrincipalArn"
      }
    }
  }

  statement {
    sid = "Lambda"
    actions = [
      "lambda:*",
    ]
    resources = [
      "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.resource_prefix}*"
    ]
  }

  // Not possible to set boundary until EKS lambda is replaced
  statement {
    sid = "LambdaENI"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
  }

  statement {
    sid = "IAM"
    actions = [
      "iam:*",
      "sts:AssumeRole*",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}*",
      "arn:aws:iam::${local.account_id}:user/${local.resource_prefix}*",
      "arn:aws:iam::${local.account_id}:instance-profile/${local.resource_prefix}*",
      "arn:aws:iam::${local.account_id}:policy/${local.resource_prefix}*",
    ]
  }

  statement {
    sid     = "DenyPassRoleOutsidePrefix"
    effect  = "Deny"
    actions = ["iam:PassRole"]
    not_resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}*"
    ]
  }

  statement {
    sid    = "RequirePBForRoles"
    effect = "Deny"
    actions = [
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values = [
        "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy_name}"
      ]
    }
  }

  statement {
    sid    = "RequirePBForUsers"
    effect = "Deny"
    actions = [
      "iam:AttachUserPolicy",
      "iam:CreateUser",
      "iam:DeleteUserPolicy",
      "iam:DetachUserPolicy",
      "iam:PutUserPermissionsBoundary",
      "iam:PutUserPolicy"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:user/${local.resource_prefix}*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values = [
        "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy_name}"
      ]
    }
  }

  statement {
    sid    = "DenyPBChanges"
    effect = "Deny"
    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy_name}"
    ]
  }

  statement {
    sid    = "NoPBDelete"
    effect = "Deny"
    actions = [
      "iam:Delete*PermissionsBoundary",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.allow_altinity_access ? [1] : []
    content {
      sid = "BreakGlass"
      actions = [
        "ssm:StartSession",
      ]
      resources = [
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    }
  }
}

locals {
  managed_policy_max_size = 6144

  pb_json     = one(data.aws_iam_policy_document.permissions-boundary-policy[*].json)
  pb_document = local.pb_json == null ? null : jsondecode(local.pb_json)

  pb_statements_without_sid = [
    for s in try(local.pb_document.Statement, []) : { for k, v in s : k => v if k != "Sid" }
  ]
  pb_json_without_sid = local.pb_document == null ? null : jsonencode(
    merge(local.pb_document, { Statement = local.pb_statements_without_sid })
  )

  pb_fits = local.pb_json == null || length(jsonencode(local.pb_document)) <= local.managed_policy_max_size

  # Sids are dropped only when the policy would not fit in a managed policy otherwise
  permissions_boundary_json = local.pb_fits ? local.pb_json : local.pb_json_without_sid
}

resource "aws_iam_policy" "altinity-permission-boundary" {
  count       = var.enable_permissions_boundary ? 1 : 0
  name        = local.permissions_boundary_policy_name
  description = "Altinity permission boundary for env ${local.env_name}"
  policy      = local.permissions_boundary_json
  lifecycle {
    precondition {
      condition     = length(replace(local.permissions_boundary_json, "/\\s/", "")) <= local.managed_policy_max_size
      error_message = "The permissions boundary policy exceeds the AWS managed policy limit of ${local.managed_policy_max_size} characters. Reduce the number of \"external_buckets\" or replace them with a wildcard pattern (e.g. \"my-prefix-*\")."
    }
  }
  tags = merge(
    local.tags,
    {
      "altinity:cloud/env" = local.env_name
      "version"            = "v1.0.0"
    }
  )
}
