variable "name" {
  description = "what it's called"
  type        = string
  default     = "fck-nat-allazs"
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "use_cloudwatch_agent" {
  description = "whether to use the CloudWatch agent"
  type        = bool
  default     = true
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
