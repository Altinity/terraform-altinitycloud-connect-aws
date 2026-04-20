# Existing VPC: deploy into pre-existing subnets instead of creating a new VPC.

provider "aws" {
  region = "us-east-1"
}

resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  # When using this example outside of this repository, replace the local
  # `source` with the public Terraform Registry reference:
  #   source  = "altinity/connect-aws/altinitycloud"
  #   version = "~> 0.3"
  source = "../.."

  pem = altinitycloud_env_certificate.this.pem

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
