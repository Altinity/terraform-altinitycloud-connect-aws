locals {
  create_vpc = !var.use_default_subnets && length(var.subnets) == 0
  create_nat = local.create_vpc && var.enable_nat_gateway
}

resource "aws_vpc" "this" {
  count      = local.create_vpc ? 1 : 0
  cidr_block = var.cidr_block
  tags       = local.tags
}

resource "aws_internet_gateway" "this" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags   = local.tags
}

resource "aws_default_route_table" "this" {
  count                  = local.create_vpc ? 1 : 0
  default_route_table_id = aws_vpc.this[0].default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }
  tags = local.tags
}

resource "aws_default_security_group" "default" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

data "aws_availability_zones" "available" {
  count = local.create_vpc ? 1 : 0
}

resource "aws_subnet" "this" {
  count                   = local.create_vpc ? min(length(data.aws_availability_zones.available[0].names), 3) : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.cidr_block == "10.0.0.0/16" ? cidrsubnet("10.0.0.0/16", 8, count.index + 1) : cidrsubnet(var.cidr_block, 2, count.index + 1)
  map_public_ip_on_launch = !local.create_nat
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  tags = merge(local.tags, {
    Name = "${local.name}-${count.index}"
  })
}

resource "aws_subnet" "nat" {
  count             = local.create_nat ? 1 : 0
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.cidr_block == "10.0.0.0/16" ? cidrsubnet("10.0.0.0/16", 8, 0) : cidrsubnet(var.cidr_block, 2, 0)
  availability_zone = data.aws_availability_zones.available[0].names[0]
  tags = merge(local.tags, {
    Name = "${local.name}-nat"
  })
}

resource "aws_eip" "nat" {
  count  = local.create_nat && var.nat_eip_allocation_id == "" ? 1 : 0
  domain = "vpc"
  tags = merge(local.tags, {
    Name = "${local.name}-nat"
  })
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count         = local.create_nat ? 1 : 0
  allocation_id = var.nat_eip_allocation_id != "" ? var.nat_eip_allocation_id : aws_eip.nat[0].id
  subnet_id     = aws_subnet.nat[0].id
  tags = merge(local.tags, {
    Name = local.name
  })
  depends_on = [aws_internet_gateway.this, aws_default_route_table.this]
}

resource "aws_route_table" "private" {
  count  = local.create_nat ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }
  tags = merge(local.tags, {
    Name = "${local.name}-private"
  })
}

resource "aws_route_table_association" "private" {
  count          = local.create_nat ? length(aws_subnet.this) : 0
  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.private[0].id
}
