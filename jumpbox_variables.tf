variable "enable_jumpbox_instance" {
  description = "Creates jumpbox instance to access resources in the VPC (SSM only)"
  type        = bool
  default     = false
}

variable "jumpbox_use_spot_instance" {
  description = "Whether to launch the jumpbox as a spot instance instead of on-demand. Recommended for cost savings since the jumpbox is a non-critical, easily-replaceable debug/access instance."
  type        = bool
  default     = true
}


locals {
  jumpbox_name     = "${local.vpc_name}-jumpbox"
  jumpbox_iam_name = "${local.jumpbox_name}-${local.region_suffix}"
}
