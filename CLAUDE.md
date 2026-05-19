# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## First Steps

**Your first tool call in this repository MUST be reading .claude/CODING_STANDARD.md.
Do not read any other files, search, or take any actions until you have read it.**
This contains InfraHouse's comprehensive coding standards for Terraform, Python, and general formatting rules.

## Module Overview

This is `terraform-aws-debian-repo`, a Terraform module that creates a Debian APT
package repository backed by S3 and fronted by CloudFront. It manages GPG key
secrets (via `infrahouse/secret/aws`), ACM certificates, Route53 DNS, and
optional HTTP basic authentication via a CloudFront function.

Requires two AWS providers: the default provider for the main region and
`aws.ue1` aliased provider for us-east-1 (ACM certificate requirement for
CloudFront).

## Commands

| Command | Purpose |
|---|---|
| `make bootstrap` | Install Python dependencies (run in a virtualenv) |
| `make format` | Format Terraform (`terraform fmt -recursive`) and Python (`black tests`) |
| `make lint` | Check Terraform formatting (`terraform fmt --check -recursive`) |
| `make test` | Run full test suite (`pytest -xvvs tests`) |
| `make test-keep` | Run tests, keep AWS resources after for debugging |
| `make test-clean` | Run tests, destroy all AWS resources after (run before PRs) |
| `make clean` | Remove `.pytest_cache`, `.terraform` directories, test state files |

Tests are integration tests that create real AWS infrastructure in account
`303467602807` using the `debian-repo-tester` role. Test region is `us-west-2`.

## Architecture

Resource files by concern (described in `main.tf`):

- **bucket.tf** - S3 bucket for repo content, access logs bucket, index.html,
  GPG public key object, bucket policies
- **cloudfront.tf** - CloudFront distribution, cache policy, HTTP auth function,
  origin access control
- **dns.tf** - Route53 A record for the repository domain
- **gpg.tf** - AWS Secrets Manager secrets for GPG private key and passphrase
  (uses `infrahouse/secret/aws` module)
- **repo.tf** - reprepro `conf/distributions` config file as S3 object
- **ssl.tf** - ACM certificate creation, DNS validation records, certificate
  validation
- **locals.tf** - Module version tag, default tags, origin ID, file paths

## Testing

Tests live in `tests/test_module.py` using pytest with `pytest-infrahouse`
fixtures. The test root module is in `test_data/test_module/`. Tests are
parametrized to cover both no-auth and HTTP basic auth scenarios.

Key test dependencies: `pytest-infrahouse`, `infrahouse-core`.

## Pre-commit Hooks

Installed via `make install-hooks` (symlinks `hooks/pre-commit`). The hook runs:
1. `terraform fmt -check -recursive`
2. `terraform-docs .` (updates README.md if needed)
3. Trailing newline check on all staged files

Hooks and several config files (`.terraform-docs.yml`, `cliff.toml`,
`mkdocs.yml`, `.claude/CODING_STANDARD.md`) are managed centrally by the
`github-control` repository — do not edit them directly.

## Releases

Use `make release-patch`, `make release-minor`, or `make release-major`. These
use `git-cliff` for changelog and `bumpversion` for version bumps. Current
version is tracked in `.bumpversion.cfg` and `locals.tf`
(`local.module_version`).