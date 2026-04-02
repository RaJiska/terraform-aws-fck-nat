terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0" # Required for region variable on resources
    }
  }
  required_version = "~> 1.3"
}
