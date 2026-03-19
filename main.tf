locals {
  is_arm             = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  ami_id             = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
  cwagent_param_arn  = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? var.cloudwatch_agent_configuration_param_arn : aws_ssm_parameter.cloudwatch_agent_config[0].arn : null
  cwagent_param_name = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? split("/", data.aws_arn.ssm_param[0].resource)[1] : aws_ssm_parameter.cloudwatch_agent_config[0].name : null
  security_groups    = concat(var.use_default_security_group ? [aws_security_group.main.id] : [], var.additional_security_group_ids)
  instance_name      = lookup(var.tags, "Name", var.name)
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "main" {
  name        = var.name
  description = "Used in ${var.name} instance of fck-nat in subnet ${var.subnet_id}"
  vpc_id      = data.aws_vpc.main.id

  tags = merge({ Name = var.name }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "vpc" {
  for_each = toset(data.aws_vpc.main.cidr_block_associations[*].cidr_block)

  security_group_id = aws_security_group.main.id
  description       = "Unrestricted ingress from within VPC"
  cidr_ipv4         = each.value
  ip_protocol       = "-1"

  tags = merge({ Name = "${var.name}-vpc-${each.value}" }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "vpc_ipv6" {
  for_each = var.use_nat64 && data.aws_vpc.main.ipv6_cidr_block != "" ? toset([data.aws_vpc.main.ipv6_cidr_block]) : toset([])

  security_group_id = aws_security_group.main.id
  description       = "Unrestricted IPv6 ingress from within VPC"
  cidr_ipv6         = each.value
  ip_protocol       = "-1"

  tags = merge({ Name = "${var.name}-vpc-ipv6-${each.value}" }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ipv4" {
  #checkov:skip=CKV_AWS_24:False positive, ingress CIDR blocks on port 22 default to "[]"
  for_each = var.use_ssh ? toset(var.ssh_cidr_blocks.ipv4) : toset([])

  security_group_id = aws_security_group.main.id
  description       = "SSH access"
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

  tags = merge({ Name = "${var.name}-ssh-${each.value}" }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ipv6" {
  #checkov:skip=CKV_AWS_24:False positive, ingress CIDR blocks on port 22 default to "[]"
  for_each = var.use_ssh ? toset(var.ssh_cidr_blocks.ipv6) : toset([])

  security_group_id = aws_security_group.main.id
  description       = "SSH access"
  cidr_ipv6         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

  tags = merge({ Name = "${var.name}-ssh-${each.value}" }, var.tags)
}

resource "aws_vpc_security_group_egress_rule" "ipv4" {
  #checkov:skip=CKV_AWS_382:Security group is used for NAT instance, intended to egress to the world
  security_group_id = aws_security_group.main.id
  description       = "Unrestricted egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge({ Name = "${var.name}-egress-ipv4" }, var.tags)
}

resource "aws_vpc_security_group_egress_rule" "ipv6" {
  #checkov:skip=CKV_AWS_382:Security group is used for NAT instance, intended to egress to the world
  security_group_id = aws_security_group.main.id
  description       = "Unrestricted egress"
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"

  tags = merge({ Name = "${var.name}-egress-ipv6" }, var.tags)
}

resource "aws_network_interface" "main" {
  description        = "${var.name} static private ENI"
  subnet_id          = var.subnet_id
  security_groups    = [aws_security_group.main.id]
  source_dest_check  = false
  ipv6_address_count = var.use_nat64 ? 1 : null

  tags = merge({ Name = var.name }, var.tags)
}

resource "aws_route" "main" {
  for_each = var.update_route_tables || var.update_route_table ? merge(var.route_tables_ids, var.route_table_id != null ? { RESERVED_FKC_NAT = var.route_table_id } : {}) : {}

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.main.id
}

resource "aws_route" "nat64" {
  for_each = var.use_nat64 && (var.update_route_tables || var.update_route_table) ? merge(var.route_tables_ids, var.route_table_id != null ? { RESERVED_FKC_NAT = var.route_table_id } : {}) : {}

  route_table_id              = each.value
  destination_ipv6_cidr_block = "64:ff9b::/96"
  network_interface_id        = aws_network_interface.main.id
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count = var.use_cloudwatch_agent && var.cloudwatch_agent_configuration_param_arn == null ? 1 : 0

  name   = "${var.name}-cloudwatch-agent-config"
  key_id = var.kms_key_id
  type   = "SecureString"
  value = templatefile("${path.module}/templates/cwagent.json", {
    METRICS_COLLECTION_INTERVAL = var.cloudwatch_agent_configuration.collection_interval,
    METRICS_NAMESPACE           = var.cloudwatch_agent_configuration.namespace
    METRICS_ENDPOINT_OVERRIDE   = var.cloudwatch_agent_configuration.endpoint_override
  })
}