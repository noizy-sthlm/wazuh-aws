terraform {
  required_version = "~> 1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
  }
}