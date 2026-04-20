---
name: Issue report
about: Report an issue or get help with the module
title: ''
labels: ''
assignees: ''

---

**Describe the issue**
A clear and concise description of the issue you're experiencing.

**Environment**
- Terraform version: [e.g. 1.9.0]
- Module version: [e.g. 0.3.0]
- AWS provider version: [e.g. 5.70.0]
- AWS region: [e.g. us-east-1]

**Error messages**
Please include any error messages or logs from:
- Terraform output
- AWS Console (CloudWatch, EC2, IAM, etc.)
- `cloud-connect` agent logs

```
Paste error messages here
```

**Module configuration**
Please provide your module configuration (remove any sensitive information):

```hcl
module "altinitycloud_connect_aws" {
  source  = "altinity/connect-aws/altinitycloud"
  version = "~> 0.3.0"
  # ...
}
```

**Terraform plan output**
If applicable, include the relevant parts of `terraform plan` output (sanitized):

```
Paste sanitized terraform plan output here
```

**Steps to reproduce**
1. Run `terraform init`
2. Run `terraform apply` with `...`
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Additional context**
Add any other context about the problem here, such as:
- Network / VPC configuration
- IAM policies / roles in use
- AltinityCloud environment status
- Any custom configurations or modifications
