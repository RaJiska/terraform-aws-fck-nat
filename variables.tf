variable "name" {
  description = "Name used for resources created within the module"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the NAT instance into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to deploy the NAT instance into"
  type        = string
}

variable "update_route_table" {
  description = "Deprecated. Use update_route_tables instead"
  type        = bool
  default     = false
}

variable "update_route_tables" {
  description = "Whether or not to update the route tables with the NAT instance"
  type        = bool
  default     = false
}

variable "route_table_id" {
  description = "Deprecated. Use route_tables_ids instead"
  type        = string
  default     = null
}

variable "route_tables_ids" {
  description = "Route tables to update. Only valid if update_route_tables is true"
  type        = map(string)
  default     = {}
}

variable "encryption" {
  description = "Whether or not to encrypt the EBS volume"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Will use the provided KMS key ID to encrypt the EBS volume. Uses the default KMS key if none provided"
  type        = string
  default     = null
}

variable "ha_mode" {
  description = "Whether or not high-availability mode should be enabled via autoscaling group"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "Instance type to use for the NAT instance"
  type        = string
  default     = "t4g.micro"
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

variable "use_ssh" {
  description = "Whether or not to enable SSH access to the NAT instance"
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "Name of the SSH key to use for the NAT instance. SSH access will be enabled only if a key name is provided"
  type        = string
  default     = null
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks to allow SSH access to the NAT instance from"
  type = object({
    ipv4 = optional(list(string), [])
    ipv6 = optional(list(string), [])
  })
  default = {
    ipv4 = [],
    ipv6 = []
  }
}

variable "tags" {
  description = "Tags to apply to resources created within the module"
  type        = map(string)
  default     = {}
}