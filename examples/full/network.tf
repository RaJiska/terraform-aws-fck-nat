resource "aws_vpc" "main" {
  cidr_block                       = local.vpc_cidr
  assign_generated_ipv6_cidr_block = local.ipv6_support

  tags = {
    Name = local.name
  }
}

### Public

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 4, 0)
  availability_zone = "${data.aws_region.current.name}a"
  ipv6_cidr_block   = local.ipv6_support ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0) : null

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "public_ipv6_igw" {
  count = local.ipv6_support ? 1 : 0

  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::0/0"
  gateway_id                  = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

### Private

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 4, 1)
  availability_zone = "${data.aws_region.current.name}a"
  ipv6_cidr_block   = local.ipv6_support ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1) : null

  tags = {
    Name = "${local.name}-private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

### Public IPv6

resource "aws_subnet" "public6" {
  count = local.ipv6_support ? 1 : 0

  vpc_id                                         = aws_vpc.main.id
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 2)
  availability_zone                              = "${data.aws_region.current.name}a"
  enable_dns64                                   = true
  ipv6_native                                    = true
  assign_ipv6_address_on_creation                = true
  enable_resource_name_dns_aaaa_record_on_launch = true

  tags = {
    Name = "${local.name}-public6"
  }
}

resource "aws_route_table" "public6" {
  count = local.ipv6_support ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-public6"
  }
}

resource "aws_route" "public6_igw" {
  count = local.ipv6_support ? 1 : 0

  route_table_id              = aws_route_table.public6[0].id
  destination_ipv6_cidr_block = "::0/0"
  gateway_id                  = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public6" {
  count = local.ipv6_support ? 1 : 0

  subnet_id      = aws_subnet.public6[0].id
  route_table_id = aws_route_table.public6[0].id
}