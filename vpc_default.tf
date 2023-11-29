data "aws_vpc" "default" {
  count   = var.use_default_subnets && length(var.subnets) == 0 ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.use_default_subnets && length(var.subnets) == 0 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}
