# SSM Parameter: load the PEM certificate from AWS SSM instead of a local file.

provider "aws" {
  region = "us-east-1"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem_ssm_parameter_name = "/altinity/cloud-connect/pem"
}
