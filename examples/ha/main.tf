# High Availability: 3 replicas with a larger instance type.

provider "aws" {
  region = "us-east-1"
}

module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem           = file("cloud-connect.pem")
  replicas      = 3
  instance_type = "t3.medium"

  tags = {
    Environment = "production"
    HA          = "true"
  }
}
