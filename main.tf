data "aws_ssm_parameter" "this" {
  count = var.pem_ssm_parameter_name != "" ? 1 : 0
  name  = var.pem_ssm_parameter_name
}

data "tls_certificate" "env_pem" {
  content = var.pem_ssm_parameter_name != "" ? one(data.aws_ssm_parameter.this).value : var.pem
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  env_name = regex("CN=([^,]+)", data.tls_certificate.env_pem.certificates[0].subject)[0]
  ami_name = (var.ami_name != "" ? var.ami_name :
  "al2023-ami-2023.2.20231113.0-kernel-6.1-${data.aws_ec2_instance_type.current.supported_architectures[0]}")
  name = "altinitycloud-connect-${random_id.this.hex}"
  tags = merge(var.tags, {
    Name                 = local.name
    "altinity:cloud/env" = local.env_name
  })
  region     = var.region != "" ? var.region : data.aws_region.current.region
  account_id = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.current.account_id
}

resource "random_id" "this" {
  byte_length = 7
}

resource "random_string" "resource_prefix" {
  count   = var.enable_permissions_boundary ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

data "aws_ec2_instance_type" "current" {
  instance_type = var.instance_type
}

data "aws_ami" "current" {
  owners = ["amazon"]
  filter {
    name = "name"
    values = [
      # Amazon Linux 2
      #
      # To lookup name when updating:
      #
      #   aws ec2 describe-images --owners amazon \
      #     --filters "Name=name,Values=al2023-ami-20*-x86_64" \
      #     --query 'reverse(sort_by(Images, &CreationDate))[].{Name:Name,ImageId:ImageId}' \
      #     --region "$region" | jq .[0]
      #
      local.ami_name
    ]
  }
  most_recent        = true
  include_deprecated = true
}

resource "aws_ssm_parameter" "this" {
  count = var.pem_ssm_parameter_name == "" ? 1 : 0
  name  = "${local.name}-secret"
  type  = "String"
  value = var.pem
  tier  = "Intelligent-Tiering"
  tags  = local.tags
}


locals {
  resource_prefix_base = (length(local.env_name) > 8 ?
  "${substr(local.env_name, 0, 4)}${substr(local.env_name, length(local.env_name) - 4, 4)}" : local.env_name)
  resource_prefix = (var.enable_permissions_boundary ?
  "${local.resource_prefix_base}-${one(random_string.resource_prefix).result}" : null)
  permissions_boundary_policy_name = var.enable_permissions_boundary ? "${local.env_name}-boundary" : null
}

resource "aws_launch_template" "this" {
  name_prefix   = "${local.name}-"
  image_id      = data.aws_ami.current.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  network_interfaces {
    associate_public_ip_address = var.map_public_ip_on_launch
    security_groups             = length(var.ec2_security_group_ids) > 0 ? var.ec2_security_group_ids : null
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = var.require_imdsv2 ? "required" : "optional"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = var.use_encrypted_volume ? "gp3" : "gp2"
      delete_on_termination = true
      encrypted             = var.use_encrypted_volume
    }
  }
  user_data = base64encode(
    templatefile("${path.module}/user-data.sh.tpl", {
      image = var.image,
      ssm_parameter_name = (var.pem_ssm_parameter_name != "" ? data.aws_ssm_parameter.this[0].name :
      aws_ssm_parameter.this[0].name)
      url           = var.url
      ca_crt        = var.ca_crt
      host_aliases  = var.host_aliases
      asg_name      = local.name
      asg_hook_name = "launch"
    })
  )
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      "terraform:altinity:cloud/instance-group" = local.name
      "altinity:cloud/version"                  = var.image
    })
  }
}

resource "aws_autoscaling_group" "this" {
  name             = local.name
  min_size         = 0
  desired_capacity = var.replicas
  max_size         = 3
  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }
  initial_lifecycle_hook {
    name                 = "launch"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    heartbeat_timeout    = "420"
    default_result       = "ABANDON"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  wait_for_capacity_timeout = "7m"
  vpc_zone_identifier = length(var.subnets) > 0 ? var.subnets : (
    var.use_default_subnets ? data.aws_subnets.default[0].ids : aws_subnet.this.*.id
  )

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
