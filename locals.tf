data "aws_region" "current" {}

locals {
  name       = "altinitycloud-connect-${random_id.this.hex}"
  create_vpc = !var.use_default_subnets && length(var.subnets) == 0

  tags = merge(var.tags, {
    Name = local.name
  })

  ami_name              = var.ami_name != "" ? var.ami_name : "al2023-ami-2023.2.20231113.0-kernel-6.1-${data.aws_ec2_instance_type.current.supported_architectures[0]}"
  arn_prefix            = startswith(data.aws_region.current.name, "cn-") ? "arn:aws-cn" : "arn:aws"
  break_glass_principal = var.break_glass_principal != "" ? var.break_glass_principal : "${local.arn_prefix}:iam::313342380333:role/AnywhereAdmin"
}

resource "random_id" "this" {
  byte_length = 7
}
