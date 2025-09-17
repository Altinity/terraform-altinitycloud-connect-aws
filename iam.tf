locals {
  # Base managed policies (always included)
  base_managed_policies = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2FullAccess",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonVPCFullAccess",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonS3FullAccess",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonRoute53FullAccess",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSLambda_FullAccess",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSQSFullAccess",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonS3TablesFullAccess",
  ]

  # Conditionally include IAMFullAccess based on scoped_iam_permissions variable
  managed_policies = var.scoped_iam_permissions ? local.base_managed_policies : concat(
    ["arn:${data.aws_partition.current.partition}:iam::aws:policy/IAMFullAccess"],
    local.base_managed_policies
  )
}

data "aws_partition" "current" {}

resource "aws_iam_role" "this" {
  name                 = "${local.name}-instance"
  description          = "Role assumed by EC2 instance(s) running altinity/cloud-connect"
  permissions_boundary = var.enable_permissions_boundary ? one(aws_iam_policy.altinity-permission-boundary).arn : null
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "this" {
  name = "${aws_iam_role.this.name}-policy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect   = "Allow",
        Action   = "eks:*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "*",
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "eks.amazonaws.com"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = "ssm:GetParameter",
        Resource = var.pem_ssm_parameter_name != "" ? data.aws_ssm_parameter.this[0].arn : aws_ssm_parameter.this[0].arn
      },
      {
        Effect = "Allow",
        Action = [
          "kafka:CreateVpcConnection",
          "kafka:GetBootstrapBrokers",
          "kafka:DescribeCluster",
          "kafka:DescribeClusterV2",
          "kafka:ListVpcConnections",
          "kafka:DeleteVpcConnection"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "vpce:AllowMultiRegion",
        Resource = "*"
      }
    ], var.scoped_iam_permissions ? [
      {
        Sid    = "IAMUserManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateUser",
          "iam:GetUser",
          "iam:DeleteUser",
          "iam:TagUser",
          "iam:ListUserTags"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::*:user/*-clickhouse-backup"
      },
      {
        Sid    = "IAMUserPolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:PutUserPolicy",
          "iam:GetUserPolicy",
          "iam:DeleteUserPolicy",
          "iam:ListUserPolicies"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::*:user/*-clickhouse-backup"
      },
      {
        Sid    = "IAMAccessKeyManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::*:user/*-clickhouse-backup"
      },
      {
        Sid    = "IAMRoleAndPolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:ListPolicyTags",
          "iam:CreateServiceLinkedRole",
          "iam:DeleteServiceLinkedRole",
          "iam:GetServiceLinkedRoleDeletionStatus",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:PassRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMReadOnlyAccess"
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*",
          "iam:SimulatePrincipalPolicy"
        ]
        Resource = "*"
      }
    ] : [])
  })
}


resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each   = toset(local.managed_policies)
  role       = aws_iam_role.this.name
  policy_arn = each.key
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name}-instance"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "altinity_break_glass" {
  count       = var.allow_altinity_access ? 1 : 0
  name        = "${local.name}-altinity-break-glass"
  description = "Role assumed by Altinity as part of break-glass procedure"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = var.break_glass_principal
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "altinity_break_glass_policy" {
  count = var.allow_altinity_access ? 1 : 0
  name  = "${aws_iam_role.altinity_break_glass[count.index].name}-policy"
  role  = aws_iam_role.altinity_break_glass[count.index].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ssm:StartSession",
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*",
        Condition = {
          StringEquals = {
            "ssm:resourceTag/terraform:altinity:cloud/instance-group" = local.name
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = "ssm:StartSession",
        Resource = "arn:${data.aws_partition.current.partition}:ssm:*:*:document/SSM-SessionManagerRunShell"
      }
    ]
  })
}
