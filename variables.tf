variable "name" {
  description = "Name used for resources created within the module"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,13}[a-z0-9])?$", var.name))
    error_message = "name must be 1-15 characters, lowercase alphanumeric and hyphens only, and cannot start or end with a hyphen."
  }
}

variable "env" {
  description = "environment name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,13}[a-z0-9])?$", var.env))
    error_message = "env must be 1-15 characters, lowercase alphanumeric and hyphens only, and cannot start or end with a hyphen."
  }
}

locals {
  is_arm             = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  ami_id             = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
  cwagent_param_arn  = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? var.cloudwatch_agent_configuration_param_arn : aws_ssm_parameter.cloudwatch_agent_config[0].arn : null
  cwagent_param_name = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? trimprefix(data.aws_arn.ssm_param[0].resource, "parameter") : aws_ssm_parameter.cloudwatch_agent_config[0].name : null
  security_groups    = concat(var.use_default_security_group ? [aws_security_group.nat_instance.id] : [], var.additional_security_group_ids)
  vpc_name           = "${var.env}-${var.name}"
  name               = "${local.vpc_name}-ngw"
  region             = data.aws_region.current.region
  account_id         = data.aws_caller_identity.current.account_id
  region_suffix      = replace(local.region, "-", "")
  iam_name           = "${local.name}-${local.region_suffix}"


  common_tags = {
    environment = var.env
    managed-by  = "terraform"
    vpc-name    = local.vpc_name
  }
}
