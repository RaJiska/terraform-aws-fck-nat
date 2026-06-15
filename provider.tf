terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80" # brilliant fork: relaxed from >= 6.0; per-resource region args stripped for provider 5.x / Atlantis TF 1.7.5
    }
  }
  required_version = "~> 1.3" # brilliant fork: relaxed from ~> 1.9; cross-variable validation removed for TF 1.7.5
}
