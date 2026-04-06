terraform {
  required_version = ">= 1.13 , ~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14 , ~> 6.0"
    }
  }
}
