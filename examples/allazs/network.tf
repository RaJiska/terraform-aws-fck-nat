data "aws_availability_zones" "azs" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_availability_zone" "az" {
  for_each = toset(data.aws_availability_zones.azs.zone_ids)
  zone_id  = each.key
}

resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_12:Ensure the default security group of every VPC restricts all traffic
  #checkov:skip=CKV2_AWS_11:Ensure VPC flow logging is enabled in all VPCs
  cidr_block                       = var.vpc_cidr
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true
  tags = {
    Name = var.name
  }
}

resource "aws_vpc_dhcp_options" "set" {
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers         = ["169.254.169.123", "fd00:ec2::123"] # AmazonProvidedNTP
  tags = {
    Name = var.name
  }
}

resource "aws_vpc_dhcp_options_association" "set" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.set.id
}

### Public

resource "aws_subnet" "public" {
  for_each                                       = toset(data.aws_availability_zones.azs.zone_ids)
  vpc_id                                         = aws_vpc.main.id
  cidr_block                                     = cidrsubnet(aws_vpc.main.cidr_block, 8, substr(each.key, -1, -1))
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, substr(each.key, -1, -1))
  availability_zone                              = data.aws_availability_zone.az[each.key].name
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch    = true
  private_dns_hostname_type_on_launch            = "resource-name"
  tags = {
    Name = "${var.name}-public-${each.key}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route" "public_ipv4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "public_ipv6" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each       = toset(data.aws_availability_zones.azs.zone_ids)
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

### Private

resource "aws_subnet" "private" {
  for_each                                       = toset(data.aws_availability_zones.azs.zone_ids)
  vpc_id                                         = aws_vpc.main.id
  cidr_block                                     = cidrsubnet(aws_vpc.main.cidr_block, 8, 10 + substr(each.key, -1, -1))
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 10 + substr(each.key, -1, -1))
  availability_zone                              = data.aws_availability_zone.az[each.key].name
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch    = true
  private_dns_hostname_type_on_launch            = "resource-name"
  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.name
  }
}

resource "aws_route_table" "private" {
  for_each = toset(data.aws_availability_zones.azs.zone_ids)
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_route" "private_ipv6" {
  for_each                    = toset(data.aws_availability_zones.azs.zone_ids)
  route_table_id              = aws_route_table.private[each.key].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_egress_only_internet_gateway.eigw.id
}

resource "aws_route_table_association" "private" {
  for_each       = toset(data.aws_availability_zones.azs.zone_ids)
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
