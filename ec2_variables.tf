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
  description = "Map of Availability Zone name to EIP allocation ID to use for the NAT instance in that AZ. Automatically assigns a public IP if not provided. Must contain an entry for every AZ used by this module when non-empty."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for az in local.azs : contains(keys(var.eip_allocation_ids), az)
    ]) || length(var.eip_allocation_ids) == 0
    error_message = "eip_allocation_ids must either be empty, or contain an entry for every AZ used by this module (${join(", ", local.azs)})."
  }
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
  default     = true
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


variable "cloud_init_parts" {
  description = "Cloud-init parts to add to the user data script"
  type = list(object({
    content      = string
    content_type = string
  }))
  default = []
}

variable "enable_health_alarms" {
  description = "Whether to create CloudWatch alarms for NAT instance ASG health (one per AZ, alarming when the ASG has 0 in-service instances)"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN to notify when a NAT instance health alarm triggers. If not provided, the module creates its own SNS topic when enable_health_alarms is true"
  type        = string
  default     = null
}

variable "alarm_email_addresses" {
  description = "List of email addresses to subscribe to the NAT instance health alarm SNS topic. Only used when the module creates its own SNS topic (i.e. alarm_sns_topic_arn is not set). Each address will receive a confirmation email that must be accepted before alarm notifications are delivered."
  type        = list(string)
  default     = []
}

locals {
  # Public subnets (for ASG/instance placement), keyed by AZ
  asg_az_subnets = { for az, s in aws_subnet.public : az => s.id }

  # Private subnets and their route tables (for the static internal ENI), keyed by AZ
  private_az_subnets      = { for az, s in aws_subnet.private : az => s.id }
  private_az_route_tables = { for az, rt in aws_route_table.private : az => rt.id }
}
