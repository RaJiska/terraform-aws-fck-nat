variable "cidr_block" {
  description = "the CIDR block for VPC to use"
  default     = "10.123.0.0/16"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Invalid CIDR provided, try the format 10.123.0.0/16."
  }
}


locals {

  # spliting the user provided CIDR block into three /19 private subnets and three /20 public subnets
  cidr_split      = flatten(cidrsubnets(var.cidr_block, 3, 3, 3, 4, 4, 4))
  private_subnets = slice(local.cidr_split, 0, 3)
  public_subnets  = slice(local.cidr_split, 3, 6)

}
