# Contributing to Terraform Altinity.Cloud AWS Connect Module

We welcome contributions to this Terraform module! This document provides guidelines for contributing and includes advanced configuration examples for development purposes.

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Install the development tooling (see [Local Tooling](#local-tooling))
4. Make your changes
5. Add tests if applicable
6. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `git commit -m 'feat: add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Development Guidelines

- Follow Terraform best practices and conventions
- Update documentation when adding new features
- Ensure all examples are working and tested
- Keep the main README user-focused and move complex examples here

## Local Tooling

This repo ships with a [pre-commit](https://pre-commit.com/) configuration that runs `terraform fmt`, `terraform validate`, [`tflint`](https://github.com/terraform-linters/tflint) and basic file hygiene checks before every commit. It also enforces [Conventional Commits](https://www.conventionalcommits.org/) on the commit message.

### Install

```bash
# macOS
brew install pre-commit terraform tflint

# or via pip
pip install pre-commit
```

### Enable the hooks

```bash
pre-commit install                       # runs hooks before each commit
pre-commit install --hook-type commit-msg # validates commit message format
```

### Run manually

```bash
# Run all hooks against every file
pre-commit run --all-files

# Or just the formatting / linting steps individually
terraform fmt -recursive
tflint --init && tflint --recursive
```

The same checks run on every Pull Request via the [`Lint & Format`](.github/workflows/lint.yml) GitHub Actions workflow.

### Allowed commit prefixes

`feat`, `fix`, `chore`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `style`, `revert`, `bump`

## Advanced Configuration Examples

The following examples are primarily intended for development and testing purposes.

### Custom Docker Image

For development and testing with custom builds:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem   = altinitycloud_env_certificate.this.pem
  image = "altinity/cloud-connect:custom-tag"
}
```

### Custom CA Certificate

For development environments with custom certificate authorities:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem    = altinitycloud_env_certificate.this.pem
  ca_crt = file("custom-ca.crt")
}
```

### Custom URL

For development environments that need to connect to a different endpoint:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem
  url = "https://other.environment.com"
}
```

### Host Aliases

For development environments that need custom host resolution:

```terraform
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"

  pem = altinitycloud_env_certificate.this.pem

  host_aliases = {
    "internal.altinity.cloud" = "10.0.1.100"
    "api.altinity.cloud"      = "10.0.1.101"
  }
}
```

## Testing

When contributing changes, please ensure:

- All Terraform configurations are valid (`terraform validate`)
- Code is formatted (`terraform fmt -recursive`)
- `tflint` passes (`tflint --recursive`)
- Examples work as expected
- Documentation is updated accordingly
- Follow the existing code style and conventions

The recommended way to run all of the above at once is `pre-commit run --all-files`.

## Questions?

If you have questions about contributing or need help with advanced configurations, please open an issue or reach out at [nacho@altinity.com](mailto:nacho@altinity.com)
