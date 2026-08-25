#######
# VPC #
#######

resource "aws_vpc" "current" {
  cidr_block                       = var.cidr_block
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = var.use_nat64

  tags = merge(local.common_tags, { "Name" = local.vpc_name })
}



#########################
# Public VPC Networking #
#########################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.current.id

  tags = merge(
    local.common_tags,
    tomap({
      "Name"         = "${local.vpc_name}-igw"
      "network-type" = "public"
    })
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.current.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = merge(
    local.common_tags,
    tomap({
      "Name"         = "${local.vpc_name}-public"
      "network-type" = "public"
    })
  )
}

resource "aws_subnet" "public" {
  count = length(local.public_subnets)

  vpc_id            = aws_vpc.current.id
  cidr_block        = local.public_subnets[count.index]
  ipv6_cidr_block   = var.use_nat64 ? cidrsubnet(aws_vpc.current.ipv6_cidr_block, 8, count.index) : null
  availability_zone = data.aws_availability_zones.available.names[count.index]


  tags = merge(
    local.common_tags,
    tomap({
      "Name"         = "${local.vpc_name}-public${count.index}"
      "network-type" = "public"
    })
  )
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public[*].id)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}



##########################
# Private VPC Networking #
##########################

resource "aws_route_table" "private" {
  count = length(local.private_subnets)

  vpc_id = aws_vpc.current.id

  tags = merge(
    local.common_tags,
    tomap({
      "Name"         = "${local.vpc_name}-private${count.index}"
      "network-type" = "private"
    })
  )
}

resource "aws_subnet" "private" {
  count = length(local.private_subnets)

  vpc_id            = aws_vpc.current.id
  cidr_block        = local.private_subnets[count.index]
  ipv6_cidr_block   = var.use_nat64 ? cidrsubnet(aws_vpc.current.ipv6_cidr_block, 8, 100 + count.index) : null
  availability_zone = data.aws_availability_zones.available.names[count.index]


  tags = merge(
    local.common_tags,
    tomap({
      "Name"         = "${local.vpc_name}-private${count.index}"
      "network-type" = "private"
    })
  )
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private[*].id)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


#######################
# NAT Gateway Routing #
#######################

resource "aws_network_interface" "main" {
  for_each = local.private_az_subnets

  region = local.region

  description        = "${local.name} static private ENI (${each.key})"
  subnet_id          = each.value
  security_groups    = [aws_security_group.main.id]
  source_dest_check  = false
  ipv6_address_count = var.use_nat64 ? 1 : null

  tags = merge(local.common_tags,{ Name = "${local.name}-${each.key}" })
}

resource "aws_route" "main" {
  for_each = local.private_az_route_tables

  region = local.region

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.main[each.key].id
}

resource "aws_route" "main_ipv6" {
  for_each = var.use_nat64 ? local.private_az_route_tables : {}

  region = local.region

  route_table_id              = each.value
  destination_ipv6_cidr_block = "64:ff9b::/96"
  network_interface_id        = aws_network_interface.main[each.key].id
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count = var.use_cloudwatch_agent && var.cloudwatch_agent_configuration_param_arn == null ? 1 : 0

  region = local.region

  name   = "${local.name}-cloudwatch-agent-config"
  key_id = var.kms_key_id
  type   = "SecureString"
  value = templatefile("${path.module}/templates/cwagent.json", {
    METRICS_COLLECTION_INTERVAL = var.cloudwatch_agent_configuration.collection_interval,
    METRICS_NAMESPACE           = var.cloudwatch_agent_configuration.namespace
    METRICS_ENDPOINT_OVERRIDE   = var.cloudwatch_agent_configuration.endpoint_override
  })
}
