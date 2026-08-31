# Service-Linked Roles: create the AWS service-linked roles required by
# Altinity.Cloud Anywhere, but only the ones missing from the account.

provider "aws" {
  region = "us-east-1"
}

resource "altinitycloud_env_certificate" "this" {
  env_name = "my-env"
}

module "altinitycloud_connect_aws" {
  # Local source: create_service_linked_roles is not in a published release yet.
  source = "../../"

  pem = altinitycloud_env_certificate.this.pem

  create_service_linked_roles = true
}
