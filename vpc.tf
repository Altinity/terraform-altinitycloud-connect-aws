locals {
  create_vpc   = !var.use_default_subnets && length(var.subnets) == 0
  create_nat   = local.create_vpc && var.enable_nat_gateway
  subnet_count = local.create_vpc ? min(length(data.aws_availability_zones.available[0].names), 3) : 0
  nat_count = !local.create_nat ? 0 : min(local.subnet_count,
  length(var.nat_eip_allocation_ids) > 0 ? length(var.nat_eip_allocation_ids) : coalesce(var.nat_gateway_count, var.replicas))
  # with NAT, instances only launch in availability zones that have a NAT gateway
  instance_subnet_ids = local.create_nat ? slice(aws_subnet.this[*].id, 0, local.nat_count) : aws_subnet.this[*].id
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
  # with NAT, the default route must not lead to the IGW: a subnet that loses its association fails closed
  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = local.create_nat ? null : aws_internet_gateway.this[0].id
    nat_gateway_id = local.create_nat ? aws_nat_gateway.this[0].id : null
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
  count                   = local.subnet_count
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.cidr_block == "10.0.0.0/16" ? cidrsubnet("10.0.0.0/16", 8, count.index + 1) : cidrsubnet(var.cidr_block, 2, count.index + 1)
  map_public_ip_on_launch = !local.create_nat
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  tags = merge(local.tags, {
    Name = "${local.name}-${count.index}"
  })
}

resource "aws_subnet" "nat" {
  count             = local.nat_count
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.cidr_block == "10.0.0.0/16" ? cidrsubnet("10.0.0.0/16", 12, count.index) : cidrsubnet(var.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available[0].names[count.index]
  tags = merge(local.tags, {
    Name = "${local.name}-nat-${count.index}"
  })
}

resource "aws_route_table" "nat" {
  count  = local.create_nat ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }
  tags = merge(local.tags, {
    Name = "${local.name}-nat"
  })
}

resource "aws_route_table_association" "nat" {
  count          = local.nat_count
  subnet_id      = aws_subnet.nat[count.index].id
  route_table_id = aws_route_table.nat[0].id
}

resource "aws_eip" "nat" {
  count  = length(var.nat_eip_allocation_ids) > 0 ? 0 : local.nat_count
  domain = "vpc"
  tags = merge(local.tags, {
    Name = "${local.name}-nat-${count.index}"
  })
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_count
  allocation_id = length(var.nat_eip_allocation_ids) > 0 ? var.nat_eip_allocation_ids[count.index] : aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.nat[count.index].id
  tags = merge(local.tags, {
    Name = "${local.name}-${count.index}"
  })
  depends_on = [aws_route_table_association.nat]
}

# the first subnet uses the default route table (first NAT gateway)
resource "aws_route_table" "private" {
  count  = max(local.nat_count - 1, 0)
  vpc_id = aws_vpc.this[0].id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index + 1].id
  }
  tags = merge(local.tags, {
    Name = "${local.name}-private-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count          = max(local.nat_count - 1, 0)
  subnet_id      = aws_subnet.this[count.index + 1].id
  route_table_id = aws_route_table.private[count.index].id
}
