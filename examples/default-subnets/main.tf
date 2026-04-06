# Default Subnets: use the default VPC subnets instead of creating new ones.

provider "aws" {
  region = "us-east-1"
}

resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem                 = altinitycloud_env_certificate.this.pem
  use_default_subnets = true
}
