# Service-Linked Roles: create the AWS service-linked roles required by
# Altinity.Cloud Anywhere in an account where they don't exist yet.

provider "aws" {
  region = "us-east-1"
}

resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  # Local source: service_linked_roles is not in a published release yet.
  source = "../../"

  pem = altinitycloud_env_certificate.this.pem

  service_linked_roles = [
    "elasticloadbalancing.amazonaws.com",
    "eks-nodegroup.amazonaws.com",
  ]
}
