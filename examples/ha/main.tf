# High Availability: 3 replicas with a larger instance type.

provider "aws" {
  region = "us-east-1"
}

resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3"

  pem           = altinitycloud_env_certificate.this.pem
  replicas      = 3
  instance_type = "t3.medium"

  tags = {
    Environment = "production"
    HA          = "true"
  }
}
