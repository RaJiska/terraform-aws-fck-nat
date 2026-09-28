terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.57.1" # region on resources, ipv6_cidr_block_associations on aws_vpc
    }
  }
  required_version = "~> 1.9" # For cross-object referencing on variables validation
}
