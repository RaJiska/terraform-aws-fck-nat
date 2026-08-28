variable "cidr_block" {
  description = "the CIDR block for VPC to use"
  default     = "10.123.0.0/16"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Invalid CIDR provided, try the format 10.123.0.0/16."
  }
}

variable "enable_athena" {
  description = "Create a Glue Catalog database/table for querying VPC flow logs (parquet, hive-partitioned) via Amazon Athena"
  type        = bool
  default     = false
}


locals {

  # splitting the user provided CIDR block into three /19 private subnets and three /20 public subnets
  cidr_split         = flatten(cidrsubnets(var.cidr_block, 3, 3, 3, 4, 4, 4))
  private_subnets    = slice(local.cidr_split, 0, 3)
  public_subnets     = slice(local.cidr_split, 3, 6)
  vpc_flow_logs_name = "${local.vpc_name}-flow-logs-${local.account_id}-${local.region_suffix}"

  # AZs used by this module, determined once from the CIDR split above (not
  # from any subnet resource), and used as the single source of truth for
  # keying every AZ-scoped resource (subnets, route tables, ENIs, ASGs, IAM
  # tag conditions, alarms, etc). Avoids re-deriving AZ order from resource
  # indexes downstream.
  azs = slice(data.aws_availability_zones.available.names, 0, length(local.private_subnets))

  public_subnet_cidrs  = { for idx, az in local.azs : az => local.public_subnets[idx] }
  private_subnet_cidrs = { for idx, az in local.azs : az => local.private_subnets[idx] }
}
