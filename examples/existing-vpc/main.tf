# Existing VPC: deploy into pre-existing subnets instead of creating a new VPC.

provider "aws" {
  region = "us-east-1"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")

  subnets = [
    "subnet-aaaa1111",
    "subnet-bbbb2222",
    "subnet-cccc3333",
  ]

  tags = {
    Environment = "production"
    VPC         = "existing"
  }
}
