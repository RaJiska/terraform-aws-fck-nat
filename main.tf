locals {
  is_arm             = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  ami_id             = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
  cwagent_param_arn  = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? var.cloudwatch_agent_configuration_param_arn : aws_ssm_parameter.cloudwatch_agent_config[0].arn : null
  cwagent_param_name = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? split("/", data.aws_arn.ssm_param[0].resource)[1] : aws_ssm_parameter.cloudwatch_agent_config[0].name : null
  security_groups    = concat(var.use_default_security_group ? [aws_security_group.main.id] : [], var.additional_security_group_ids)
  route_table_ids    = var.update_route_table ? var.route_tables_ids : {}

  route_entries = flatten([
    for rt_id in local.route_table_ids : [
      for cidr in var.destination_cidr_blocks : {
        route_table_id         = rt_id
        destination_cidr_block = cidr
      }
    ]
  ])

}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "main" {
  #checkov:skip=CKV_AWS_24:False positive from Checkov, ingress CIDR blocks on port 22 default to "[]"
  name        = var.name
  description = "Used in ${var.name} instance of fck-nat in subnet ${var.subnet_id}"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Unrestricted ingress from within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.aws_vpc.main.cidr_block_associations[*].cidr_block
  }

  dynamic "ingress" {
    for_each = var.use_ssh && (length(var.ssh_cidr_blocks.ipv4) > 0 || length(var.ssh_cidr_blocks.ipv6) > 0) ? [1] : [] #  

    content {
      description      = "SSH access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = var.ssh_cidr_blocks.ipv4
      ipv6_cidr_blocks = var.ssh_cidr_blocks.ipv6
    }
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
  description       = "${var.name} static private ENI"
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.main.id]
  source_dest_check = false

  tags = merge({ Name = var.name }, var.tags)
}

resource "aws_route" "main" {
  for_each = {
    for idx, route in local.route_entries :
    "${route.route_table_id}_${replace(route.destination_cidr_block, "/", "-")}" => route
  }
  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  network_interface_id   = aws_network_interface.main.id
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
