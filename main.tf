locals {
  is_arm            = regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type) == var.instance_type
  ami_id            = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
  cwagent_param_arn = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? var.cloudwatch_agent_configuration_param_arn : aws_ssm_parameter.cloudwatch_agent_config[0].arn : null
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

  ingress {
    description = "Unrestricted ingress from within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]
  }

  egress {
    description      = "Unrestricted egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_network_interface" "main" {
  description       = "${var.name} static private ENI"
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.main.id]
  source_dest_check = false

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_route" "main" {
  count = var.update_route_table ? 1 : 0

  route_table_id         = var.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.main.id
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count = var.use_cloudwatch_agent && var.cloudwatch_agent_configuration_param_arn == null ? 1 : 0

  name   = "${var.name}-cloudwatch-agent-config"
  key_id = var.kms_key_id
  type   = "String"
  value = templatefile("${path.module}/templates/cwagent.json", {
    METRICS_COLLECTION_INTERVAL = var.cloudwatch_agent_configuration.collection_interval,
    METRICS_NAMESPACE           = var.cloudwatch_agent_configuration.namespace
    METRICS_ENDPOINT_OVERRIDE   = var.cloudwatch_agent_configuration.endpoint_override
  })
}