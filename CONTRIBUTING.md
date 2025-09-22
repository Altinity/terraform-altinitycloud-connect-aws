# Contributing to Terraform Altinity.Cloud AWS Connect Module

We welcome contributions to this Terraform module! This document provides guidelines for contributing and includes advanced configuration examples for development purposes.

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Guidelines

- Follow Terraform best practices and conventions
- Update documentation when adding new features
- Ensure all examples are working and tested
- Keep the main README user-focused and move complex examples here

## Advanced Configuration Examples

The following examples are primarily intended for development and testing purposes.

### Custom Docker Image

For development and testing with custom builds:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem   = file("cloud-connect.pem")
  image = "altinity/cloud-connect:custom-tag"
}
```

### Custom CA Certificate

For development environments with custom certificate authorities:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem    = file("cloud-connect.pem")
  ca_crt = file("custom-ca.crt")
}
```

### Custom URL

For development environments that need to connect to a different endpoint:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")
  url = "https://other.environment.com"
}
```

### Host Aliases

For development environments that need custom host resolution:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.2.0"

  pem = file("cloud-connect.pem")

  host_aliases = {
    "internal.altinity.cloud" = "10.0.1.100"
    "api.altinity.cloud"      = "10.0.1.101"
  }
}
```

## Testing

When contributing changes, please ensure:

- All Terraform configurations are valid (`terraform validate`)
- Examples work as expected
- Documentation is updated accordingly
- Follow the existing code style and conventions

## Questions?

If you have questions about contributing or need help with advanced configurations, please open an issue or reach out at [nacho@altinity.com](mailto:nacho@altinity.com)
