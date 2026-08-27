variable "name" {
  description = "Name used for resources created within the module"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
}

locals {
  is_arm             = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  ami_id             = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
  cwagent_param_arn  = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? var.cloudwatch_agent_configuration_param_arn : aws_ssm_parameter.cloudwatch_agent_config[0].arn : null
  cwagent_param_name = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? trimprefix(data.aws_arn.ssm_param[0].resource, "parameter") : aws_ssm_parameter.cloudwatch_agent_config[0].name : null
  security_groups    = concat(var.use_default_security_group ? [aws_security_group.main.id] : [], var.additional_security_group_ids)
  vpc_name           = "${var.env}-${var.name}"
  name               = "${local.vpc_name}-ngw"
  region             = data.aws_region.current.region


  common_tags = {
    environment = var.env
    managed-by  = "terraform"
    vpc-name    = local.vpc_name
  }
}
