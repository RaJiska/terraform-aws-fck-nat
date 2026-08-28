data "aws_region" "current" {}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "main" {
  count = var.ami_id != null ? 0 : 1

  # Region is determined by the configured AWS provider

  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = [var.use_nat64 ? "fck-nat-nat64-al2023-hvm-*" : "fck-nat-al2023-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = [local.is_arm ? "arm64" : "x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_arn" "ssm_param" {
  count = var.use_cloudwatch_agent && var.cloudwatch_agent_configuration_param_arn != null ? 1 : 0

  arn = var.cloudwatch_agent_configuration_param_arn
}



