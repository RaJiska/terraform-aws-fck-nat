terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0" # Required by data.aws_region.current.region
    }
  }
  required_version = "~> 1.3"
}