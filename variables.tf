variable "name" {
  description = "Name used for resources created within the module"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
}

variable "region" {
  description = "Region in which to create resources, defaults to provider region if not set"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "Will use the provided KMS key ID to encrypt the EBS volume. Uses the default KMS key if none provided"
  type        = string
  default     = null
}

variable "auto_rollout" {
  description = "Whether to automatically rollout configuration changes to the launch template (like AMI and cloud init)"
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "Instance type to use for the NAT instance"
  type        = string
  default     = "t4g.micro"
}

variable "ha_additional_instance_types" {
  description = "List of additional instance types to pass to the ASG, helpful when using spot instances with low availabiltiy"
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "AMI to use for the NAT instance. Uses fck-nat latest AMI in the region if none provided"
  type        = string
  default     = null
}

variable "ebs_root_volume_size" {
  description = "Size of the EBS root volume in GB"
  type        = number
  default     = 8
}

variable "eip_allocation_ids" {
  description = "EIP allocation IDs to use for the NAT instance. Automatically assign a public IP if none is provided. Note: Currently only supports at most one EIP allocation."
  type        = list(string)
  default     = []
}

variable "attach_ssm_policy" {
  description = "Whether to attach the minimum required IAM permissions to connect to the instance via SSM."
  type        = bool
  default     = true
}

variable "credit_specification" {
  description = "Customize the credit specification of the instance"
  type        = string
  default     = null
}

variable "use_spot_instances" {
  description = "Whether or not to use spot instances for running the NAT instance"
  type        = bool
  default     = false
}

variable "use_cloudwatch_agent" {
  description = "Whether or not to enable CloudWatch agent for the NAT instance"
  type        = bool
  default     = false
}

variable "cloudwatch_agent_configuration" {
  description = "CloudWatch configuration for the NAT instance"
  type = object({
    namespace           = optional(string, "fck-nat"),
    collection_interval = optional(number, 60),
    endpoint_override   = optional(string, "")
  })
  default = {
    namespace           = "fck-nat"
    collection_interval = 60
    endpoint_override   = ""
  }
}

variable "cloudwatch_agent_configuration_param_arn" {
  description = "ARN of the SSM parameter containing the CloudWatch agent configuration. If none provided, creates one"
  type        = string
  default     = null
}

variable "use_default_security_group" {
  description = "Whether or not to use the default security group for the NAT instance"
  type        = bool
  default     = true
}

variable "additional_security_group_ids" {
  description = "A list of identifiers of security groups to be added for the NAT instance"
  type        = list(string)
  default     = []
}

variable "use_nat64" {
  description = "Whether or not to enable NAT64 on the NAT instance. Your VPC and at least the public subnet this NAT instance is deployed into must support IPv6"
  type        = bool
  default     = false
}

variable "permissions_boundary_arn" {
  description = "ARN of the IAM policy to use as a permissions boundary for the NAT instance IAM role"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources created within the module"
  type        = map(string)
  default     = {}
}

variable "cloud_init_parts" {
  description = "Cloud-init parts to add to the user data script"
  type = list(object({
    content      = string
    content_type = string
  }))
  default = []
}


locals {
  is_arm             = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  ami_id             = var.ami_id != null ? var.ami_id : data.aws_ami.main[0].id
  cwagent_param_arn  = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? var.cloudwatch_agent_configuration_param_arn : aws_ssm_parameter.cloudwatch_agent_config[0].arn : null
  cwagent_param_name = var.use_cloudwatch_agent ? var.cloudwatch_agent_configuration_param_arn != null ? trimprefix(data.aws_arn.ssm_param[0].resource, "parameter") : aws_ssm_parameter.cloudwatch_agent_config[0].name : null
  security_groups    = concat(var.use_default_security_group ? [aws_security_group.main.id] : [], var.additional_security_group_ids)
  instance_name      = lookup(var.tags, "Name", var.name)
  vpc_name           = "${var.env}-${var.name}"


  common_tags = {
    environment = var.env
    managed-by  = "terraform"
    vpc-name    = local.vpc_name
  }
}
