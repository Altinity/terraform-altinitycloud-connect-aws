resource "aws_iam_role" "this" {
  name        = "${local.name}-instance"
  description = "Role assumed by EC2 instance(s) running altinity/cloud-connect"
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
  inline_policy {
    name = "inline"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
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
        }
      ]
    })
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    # for aws ssm start-session
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
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
  inline_policy {
    name = "root"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect   = "Allow",
          Action   = "ssm:StartSession",
          Resource = "arn:aws:ec2:*:*:instance/*",
          Condition = {
            StringEquals = {
              "ssm:resourceTag/terraform:altinity:cloud/instance-group" = local.name
            }
          }
        },
        {
          Effect   = "Allow",
          Action   = "ssm:StartSession",
          Resource = "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
        }
      ]
    })
  }
}
