data "aws_availability_zone" "az" {
  for_each = toset(data.aws_availability_zones.azs.zone_ids)
  zone_id  = each.key
}

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr

  tags = {
    Name = local.name
  }
}

### Public

resource "aws_subnet" "public" {
  for_each          = toset(data.aws_availability_zones.azs.zone_ids)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.255.${substr(each.key, -1, -1)}.0/24"
  availability_zone = data.aws_availability_zone.az[each.key].name

  tags = {
    Name = "${local.name}-public-${each.key}"
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

resource "aws_route_table_association" "public" {
  for_each       = toset(data.aws_availability_zones.azs.zone_ids)
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

### Private

resource "aws_subnet" "private" {
  for_each          = toset(data.aws_availability_zones.azs.zone_ids)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.255.${10 + substr(each.key, -1, -1)}.0/24"
  availability_zone = data.aws_availability_zone.az[each.key].name

  tags = {
    Name = "${local.name}-private-${each.key}"
  }
}

resource "aws_route_table" "private" {
  for_each = toset(data.aws_availability_zones.azs.zone_ids)
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${local.name}-private-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = toset(data.aws_availability_zones.azs.zone_ids)
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
