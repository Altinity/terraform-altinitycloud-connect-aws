

data "aws_iam_policy_document" "perm-boundary-policy" {
  count = var.permission_boundary ? 1 : 0

  statement {
    sid = "DescribeResourcesInRegion"
    actions = [
      "ec2:Describe*",
      "autoscaling:Describe*",
      "elasticloadbalancing:Describe*",
      "route53:ListHostedZonesByVPC"
    ]

    resources = ["*"]
  }

  statement {
    sid = "MessageGatewayServiceInRegion"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]

    resources = ["*"]
  }

  statement {
    sid = "EnvRequestTagBasedAccess"

    actions = [
      "ec2:CreateVpc",
      "ec2:CreateInternetGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateVpcEndpoint",
      "ec2:CreateSubnet",
      "ec2:RunInstances",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateVolume",
      "ec2:CreateNetworkInterface",
      "ec2:CreateSecurityGroup",
      "ec2:AllocateAddress",
      "ec2:CreateNatGateway",
      "ec2:CreateVpcEndpointServiceConfiguration",
      "ec2:CreateVpcPeeringConnection",
    ]

    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      values = [var.env_name]
      variable = "aws:RequestTag/altinity:cloud/env"
    }
  }

  statement {
    effect = "Deny"

    sid = "DenyTagsModificationOnNonManagedResources"

    actions = [
      "ec2:CreateTags",
    ]

    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringNotEquals"
      values = [var.env_name]
      variable = "aws:ResourceTag/altinity:cloud/env"
    }
  }

  statement {
    sid = "EnvCreateRequestTagBasedAccess"

    actions = [
      "ec2:CreateTags",
    ]

    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      values = [
        "CreateVpc",
        "CreateInternetGateway",
        "CreateRoute",
        "CreateRouteTable",
        "CreateVpcEndpoint",
        "CreateSubnet",
        "RunInstances",
        "CreateLaunchTemplate",
        "CreateVolume",
        "CreateNetworkInterface",
        "CreateSecurityGroup",
        "AllocateAddress",
        "CreateNatGateway",
        "CreateVpcEndpointServiceConfiguration",
        "CreateVpcPeeringConnection",
      ]
      variable = "ec2:CreateAction"
    }
  }


  statement {
    sid = "EnvResourceTagBasedAccess"

    actions = [
      "ssm:*",
      "ec2:*",
      "eks:*",
      "iam:*",
      "ssm:*",
      "lambda:*",
      "autoscaling:*",
      "elasticloadbalancing:*",
    ]

    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      values = [var.env_name]
      variable = "aws:ResourceTag/altinity:cloud/env"
    }
  }

  statement {
    sid = "EKSPodIdentity"

    actions = [
      "eks-auth:AssumeRoleForPodIdentity",
    ]

    resources = [
      "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.resource_prefix}"
    ]
  }

  statement {
    sid = "EKSDescribeCluster"

    actions = [
      "eks:DescribeCluster",
    ]

    resources = [
      "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.resource_prefix}"
    ]
  }

  statement {
    sid = "EKSNodePoolsAMIs"

    actions = [
      "ec2:RunInstances",
    ]
    resources = ["arn:aws:ec2:${local.region}::image/ami-*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      values = ["amazon"]
      variable = "ec2:Owner"
    }
  }

  statement {
    sid = "EKSNodesImages"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = ["*"]
  }

  statement {
    sid = "EKSOpenIDConnectProvider"
    actions = [
      "iam:GetOpenIDConnectProvider",
    ]

    resources = ["arn:aws:iam::${local.account_id}:oidc-provider/oidc.eks.${local.region}.amazonaws.com/id/*"]
  }

  statement {
    sid = "EKSNodeGroups"

    actions = [
      "eks:DescribeNodegroup",
    ]

    resources = ["arn:aws:eks:${local.region}:${local.account_id}:nodegroup/${local.resource_prefix}/*"]
  }

  statement {
    sid = "EKSAutoscalingGroups"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:CreateOrUpdateTags",
    ]

    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      values = [local.resource_prefix]
      variable = "aws:ResourceTag/eks:cluster-name"
    }
  }

  statement {
    sid = "EKSTagSecurityGroup"

    actions = [
      "ec2:CreateTags"
    ]

    resources = ["arn:aws:ec2:${local.region}:${local.account_id}:security-group/*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      values = [local.resource_prefix]
      variable = "aws:ResourceTag/aws:eks:cluster-name"
    }
  }

  statement {
    sid = "EKSIAMRole"

    actions = [
      "iam:GetRole",
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup"
    ]
  }

  statement {
    sid = "S3"

    actions = [
      "s3:*",
    ]

    resources = ["arn:aws:s3:::${local.resource_prefix}-*"]
  }

  statement {
    sid = "Lambda"

    actions = [
      "lambda:*",
    ]

    resources = [
      "arn:aws:lambda:${local.region}:${local.account_id}:function:${local.resource_prefix}-*"
    ]
  }

  // Not possible to set boundary until EKS lambda is replaced
  statement {
    sid = "LambdaNetworkInterface"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
    ]

    resources = ["*"]
  }

  statement {
    sid = "EnvAssumeAndPassCreatedRoles"

    actions = [
      "sts:AssumeRole",
      "sts:AssumeRoleWithWebIdentity",
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}-*"
    ]
  }

  statement {
    sid = "EnvIAMEntities"

    actions = [
      "iam:*"
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}-*",
      "arn:aws:iam::${local.account_id}:user/${local.resource_prefix}-*",
      "arn:aws:iam::${local.account_id}:instance-profile/${local.resource_prefix}-*",
      "arn:aws:iam::${local.account_id}:policy/${local.resource_prefix}-*",
    ]
  }

  statement {
    sid = "RequirePermissionBoundaryForCreatedRoles"

    actions = [
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${local.resource_prefix}-*"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"

      values = [
        "arn:aws:iam::${local.account_id}:policy/${local.permission_boundary_policy_name}"
      ]
    }
  }

  statement {
    sid = "DenyPermissionBoundaryChanges"

    effect = "Deny"

    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:policy/${local.permission_boundary_policy_name}"
    ]
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
  count = var.permission_boundary ? 1 : 0
  name   = local.permission_boundary_policy_name
  description = "Altinity permission boundary for env ${var.env_name}"
  policy = one(data.aws_iam_policy_document.perm-boundary-policy).json
}

