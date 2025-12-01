# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.5](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.2.4...v0.2.5)

### Changed
- Rollback support to AWS provider v5 [267fff8](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/267fff8).

### Fixed
- Add missing vpce:AllowMultiRegion to permissions boundary policy [5c8f740](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/5c8f740).

## [0.2.4](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.2.3...v0.2.4)

### Added
- Add variables to customize ebs volume size and type [351609d](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/351609d).


## [0.2.3](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.2.2...v0.2.3)

### Added
- Add `ami_name` variable to allow custom AMI lookup [16d036e](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/16d036e).

## [0.2.2](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.2.1...v0.22)

### Fixed
- Update how security group is set in auto scaling group [7ec3aa3](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/7ec3aa3).

## [0.2.1](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.2.0...v0.2.1)

### Fixed
- Add missing `UpdateAssumeRolePolicy` permission [652988c](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/652988c).

## [0.2.0](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.18...v0.2.0)

### Added
- Restrict AWS IAM permissions [#14](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/14).
- Allow restricted IAM permissions for the IAM role [#11](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/11).

### Changed
- Improve readme and add contributing [c36bcfc](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/c36bcfc).
- Change default cloud-connect image to 0.133.0 [07596ba](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/07596ba).

## [0.1.18](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.17...v0.1.18)

### Added
- Add AmazonS3TablesFullAccess policy [e261d97](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/e261d97).

## [0.1.17](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.16...v0.1.17)

### Added
- Extend permissions boundary to include limited SQS access [#13](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/13).

## [0.1.16](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.15...v0.1.16)

### Added
- Add sqs policy for iceberg watch [30ad957](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/30ad957).

## [0.1.15](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.14...v0.1.15)

### Added
- Add permission for vpce cross region [#12](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/12).

## [0.1.14](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.13...v0.1.14)

### Changed
- Remove deprecated aws region name [f9a7b36](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/f9a7b36).

## [0.1.13](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.12...v0.1.13)

### Added
- Allow IMDSv2 for EC2 instances [9672238](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/9672238).
- Simplify permissions boundary document to reduce its size, add version tag [#10](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/10).

## [0.1.12](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.11...v0.1.12)

### Added
- Add external S3 bucket support to permissions boundary [#8](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/8).

## [0.1.11](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.10...v0.1.11)

### Fixed
- Update IAM permission boundaries for roles and users [#7](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/7).

## [0.1.10](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.9...v0.1.10)

### Added
- AWS permission boundary [#6](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/6).

## [0.1.9](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.8...v0.1.9)

### Fixed
- Correct subnets for custom cidr_block [9040a06](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/9040a06).

## [0.1.8](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.7...v0.1.8)

### Fixed
- Update permission for break-glass [2b18282](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/2b18282).

## [0.1.7](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.6...v0.1.7)

### Changed
- Ignore terraform files [51bd584](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/51bd584).

### Added
- Allow ec2 security group configuration [1f72a91](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/1f72a91).

## [0.1.6](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.5...v0.1.6)

### Added
- Add CIDR variable [2af347a](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/2af347a).

### Changed
- Migrate inline and managed policies [#4](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/4).

## [0.1.5](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.4...v0.1.5)

### Added
- Include perms to manage MSK VPC connections [a6fb948](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/a6fb948).

## [0.1.4](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.3...v0.1.4)

### Changed
- Bump cloudconnect to 0.88.0 [5fdb9fd](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/5fdb9fd).

## [0.1.3](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.2...v0.1.3)

### Fixed
- Account for different AWS partitions [#2](https://github.com/Altinity/terraform-altinitycloud-connect-aws/pull/2).

## [0.1.2](https://github.com/Altinity/terraform-altinitycloud-connect-aws/compare/v0.1.1...v0.1.2)

### Added
- Make ec2 ami configurable [1bde96d](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/1bde96d).

## [0.1.1](https://github.com/Altinity/terraform-altinitycloud-connect-aws/releases/tag/v0.1.1)

### Added
- Add missing usage header to the readme [428b942](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/428b942).

### Changed
- Update readme [4a57219](https://github.com/altinity/terraform-altinitycloud-connect-aws/commit/4a57219).
