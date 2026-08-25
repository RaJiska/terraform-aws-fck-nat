
resource "aws_security_group" "main" {
  #checkov:skip=CKV_AWS_24:False positive, ingress CIDR blocks on port 22 default to "[]"
  #checkov:skip=CKV_AWS_382:Security group is used for NAT instance, intended to egress to the world
  region = var.region

  name        = var.name
  description = "Used in ${var.name} instance of fck-nat"
  vpc_id      = aws_vpc.current.id

  ingress {
    description      = "Unrestricted ingress from within VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.current.cidr_block]
    ipv6_cidr_blocks = var.use_nat64 ? [aws_vpc.current.ipv6_cidr_block] : null
  }

  egress {
    description      = "Unrestricted egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({ Name = var.name }, var.tags)
}

resource "aws_network_interface" "main" {
  for_each = local.private_az_subnets

  region = var.region

  description        = "${var.name} static private ENI (${each.key})"
  subnet_id          = each.value
  security_groups    = [aws_security_group.main.id]
  source_dest_check  = false
  ipv6_address_count = var.use_nat64 ? 1 : null

  tags = merge({ Name = "${var.name}-${each.key}" }, var.tags)
}

resource "aws_route" "main" {
  for_each = local.private_az_route_tables

  region = var.region

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.main[each.key].id
}

resource "aws_route" "main_ipv6" {
  for_each = var.use_nat64 ? local.private_az_route_tables : {}

  region = var.region

  route_table_id              = each.value
  destination_ipv6_cidr_block = "64:ff9b::/96"
  network_interface_id        = aws_network_interface.main[each.key].id
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count = var.use_cloudwatch_agent && var.cloudwatch_agent_configuration_param_arn == null ? 1 : 0

  region = var.region

  name   = "${var.name}-cloudwatch-agent-config"
  key_id = var.kms_key_id
  type   = "SecureString"
  value = templatefile("${path.module}/templates/cwagent.json", {
    METRICS_COLLECTION_INTERVAL = var.cloudwatch_agent_configuration.collection_interval,
    METRICS_NAMESPACE           = var.cloudwatch_agent_configuration.namespace
    METRICS_ENDPOINT_OVERRIDE   = var.cloudwatch_agent_configuration.endpoint_override
  })
}
