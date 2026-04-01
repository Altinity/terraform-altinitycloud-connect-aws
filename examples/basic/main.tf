# Basic setup: minimal configuration using a PEM file.

provider "aws" {
  region = "us-east-1"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")
}
