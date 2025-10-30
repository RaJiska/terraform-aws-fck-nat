variable "name" {
  description = "what it's called"
  type        = string
  default     = "fck-nat-allazs"
}

variable "vpc_cidr" {
  description = "IPv4 RFC1918 CIDR"
  type        = string
  default     = "10.255.0.0/16"
}

variable "deploy_nat_per_az" {
  description = "whether to deploy a NAT instance in each AZ"
  type        = bool
  default     = true
}

variable "deploy_single_nat" {
  description = "whether to deploy a single NAT instance"
  type        = bool
  default     = false
}

variable "use_cloudwatch_agent" {
  description = "whether to use the CloudWatch agent"
  type        = bool
  default     = true
}

variable "ha_mode" {
  description = "whether to deploy NAT instance(s) in HA mode"
  type        = bool
  default     = false
}

variable "use_spot_instances" {
  description = "whether to use Spot instances"
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.nano"
}
