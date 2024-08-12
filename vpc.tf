resource "aws_vpc" "this" {
  count      = local.create_vpc ? 1 : 0
  cidr_block = "10.0.0.0/16"
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
  cidr_block              = "10.0.${count.index + 1}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  tags = merge(local.tags, {
    Name = "${local.name}-${count.index}"
  })
}
