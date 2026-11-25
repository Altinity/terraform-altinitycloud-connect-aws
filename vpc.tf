locals {
  create_vpc   = !var.use_default_subnets && length(var.subnets) == 0
  create_nat   = local.create_vpc && var.enable_nat_gateway
  subnet_count = local.create_vpc ? min(length(data.aws_availability_zones.available[0].names), 3) : 0
  nat_count = !local.create_nat ? 0 : min(local.subnet_count,
  length(var.nat_eip_allocation_ids) > 0 ? length(var.nat_eip_allocation_ids) : var.nat_gateway_count)
  subnet_newbits = var.cidr_block == "10.0.0.0/16" ? 8 : 2
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
  dynamic "route" {
    for_each = var.standalone_routes ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      gateway_id     = local.create_nat ? null : aws_internet_gateway.this[0].id
      nat_gateway_id = local.create_nat ? aws_nat_gateway.this[0].id : null
    }
  }
  tags = local.tags
}

resource "aws_route" "default" {
  count                  = local.create_vpc && var.standalone_routes ? 1 : 0
  route_table_id         = aws_default_route_table.this[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.create_nat ? null : aws_internet_gateway.this[0].id
  nat_gateway_id         = local.create_nat ? aws_nat_gateway.this[0].id : null
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
  cidr_block              = cidrsubnet(var.cidr_block, local.subnet_newbits, count.index + 1)
  map_public_ip_on_launch = !local.create_nat
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  tags = merge(local.tags, {
    Name = "${local.name}-${count.index}"
  })
}

resource "aws_subnet" "nat" {
  count  = local.nat_count
  vpc_id = aws_vpc.this[0].id
  # carved out of block 0, which aws_subnet.this never uses
  cidr_block        = cidrsubnet(cidrsubnet(var.cidr_block, local.subnet_newbits, 0), 2, count.index)
  availability_zone = data.aws_availability_zones.available[0].names[count.index]
  tags = merge(local.tags, {
    Name = "${local.name}-nat-${count.index}"
  })
  lifecycle {
    precondition {
      condition     = tonumber(split("/", var.cidr_block)[1]) <= 24
      error_message = "enable_nat_gateway requires \"cidr_block\" to be /24 or larger."
    }
  }
}

resource "aws_route_table" "nat" {
  count  = local.create_nat ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  dynamic "route" {
    for_each = var.standalone_routes ? [] : [1]
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.this[0].id
    }
  }
  tags = merge(local.tags, {
    Name = "${local.name}-nat"
  })
}

resource "aws_route" "nat" {
  count                  = local.create_nat && var.standalone_routes ? 1 : 0
  route_table_id         = aws_route_table.nat[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
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
    Name = "${local.name}-nat-${count.index}"
  })
  depends_on = [aws_route_table_association.nat, aws_route.nat]
  lifecycle {
    precondition {
      condition     = length(var.nat_eip_allocation_ids) <= local.subnet_count
      error_message = "nat_eip_allocation_ids has more entries than subnets (availability zones, up to 3) created by this module."
    }
  }
}

# with more than one NAT gateway, each subnet gets its own route table; subnets without a NAT gateway in their AZ use the first one
resource "aws_route_table" "this" {
  count  = local.nat_count > 1 ? local.subnet_count : 0
  vpc_id = aws_vpc.this[0].id
  dynamic "route" {
    for_each = var.standalone_routes ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[count.index < local.nat_count ? count.index : 0].id
    }
  }
  tags = merge(local.tags, {
    Name = "${local.name}-${count.index}"
  })
}

resource "aws_route" "this" {
  count                  = var.standalone_routes ? length(aws_route_table.this) : 0
  route_table_id         = aws_route_table.this[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index < local.nat_count ? count.index : 0].id
}

resource "aws_route_table_association" "this" {
  count          = local.nat_count > 1 ? local.subnet_count : 0
  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.this[count.index].id
}
