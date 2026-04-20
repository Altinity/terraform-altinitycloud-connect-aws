terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    altinitycloud = {
      source  = "altinity/altinitycloud"
      version = ">= 0.5"
    }
  }
}
