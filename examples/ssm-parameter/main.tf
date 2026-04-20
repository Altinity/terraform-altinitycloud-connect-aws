# SSM Parameter: load the PEM certificate from AWS SSM instead of a local file.

provider "aws" {
  region = "us-east-1"
}

module "altinitycloud_connect_aws" {
  # When using this example outside of this repository, replace the local
  # `source` with the public Terraform Registry reference:
  #   source  = "altinity/connect-aws/altinitycloud"
  #   version = "~> 0.3"
  source = "../.."

  pem_ssm_parameter_name = "/altinity/cloud-connect/pem"
}
