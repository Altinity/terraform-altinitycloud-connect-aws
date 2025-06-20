data "aws_iam_policy_document" "permissions-boundary-policy" {
  count = var.enable_permissions_boundary ? 1 : 0

  statement {
    sid = "Read"
    actions = [
      "ec2:Describe*",
      "autoscaling:Describe*",
      "elasticloadbalancing:Describe*",
      "route53:ListHostedZonesByVPC"
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
    sid = "EKSAuth"
    actions = [
      "eks-auth:AssumeRoleForPodIdentity",
      "eks:DescribeCluster"
    ]
    resources = [
      "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.resource_prefix}"
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
    sid = "EKSNG"
    actions = [
      "eks:DescribeNodegroup",
    ]
    resources = ["arn:aws:eks:${local.region}:${local.account_id}:nodegroup/${local.resource_prefix}/*"]
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
    sid = "EKSRole"
    actions = [
      "iam:GetRole",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/aws-service-role/eks-nodegroup.amazonaws.com/*"
    ]
  }

  statement {
    sid = "S3"
    actions = [
      "s3:*",
    ]
    resources = ["arn:aws:s3:::${local.resource_prefix}*"]
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
    sid = "AssumeAndPassEnvRoles"
    actions = [
      "sts:AssumeRole*",
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}*"
    ]
  }

  statement {
    sid = "IAM"
    actions = [
      "iam:*"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}*",
      "arn:aws:iam::${local.account_id}:user/${local.resource_prefix}*",
      "arn:aws:iam::${local.account_id}:instance-profile/${local.resource_prefix}*",
      "arn:aws:iam::${local.account_id}:policy/${local.resource_prefix}*",
    ]
  }

  statement {
    sid    = "RequirePBForRoles"
    effect = "Deny"
    actions = [
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy"
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

resource "aws_iam_policy" "altinity-permission-boundary" {
  count       = var.enable_permissions_boundary ? 1 : 0
  name        = local.permissions_boundary_policy_name
  description = "Altinity permission boundary for env ${local.env_name}"
  policy      = one(data.aws_iam_policy_document.permissions-boundary-policy).json
  tags = merge(
    local.tags,
    {
      "altinity:cloud/env" = local.env_name
      "version"            = "v1.0.0"
    }
  )
}
