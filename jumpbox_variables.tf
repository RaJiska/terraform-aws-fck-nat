variable "enable_jumpbox_instance" {
  description = "Creates jumpbox instance to access resources in the VPC (SSM only)"
  type        = bool
  default     = false
}


locals {
  jumpbox_name = "${local.vpc_name}-jumpbox"
}
