# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform Infrastructure as Code (IaC) project for managing GitHub repositories using Terraform and GitHub Actions. The repository automates the creation, configuration, and protection of multiple GitHub repositories.

## Architecture

### Module Structure

- **`terraform/modules/repository/`**: Reusable Terraform module for GitHub repository management
  - Handles repository creation, branch protection, Actions permissions, and repository rulesets
  - Key resources: `github_repository`, `github_branch_protection`, `github_actions_repository_permissions`

- **`terraform/src/repository/`**: Repository-specific Terraform configurations
  - Each `.tf` file defines a GitHub repository using the module
  - Common files: `main.tf`, `provider.tf`, `terraform.tf`, `variables.tf`

### GitHub Actions Structure

- **`.github/workflows/`**: CI/CD workflows
  - `terraform-github.yml`: Main workflow for plan/apply
  - `terraform-import.yml`: Import existing repositories
  - `pre-commit.yml`: Code quality checks

- **`.github/actions/`**: Custom reusable actions
  - `setup-terraform`: Initialize and format check
  - `terraform-validate`: Validation and linting
  - `terraform-plan`: Plan with PR comments
  - `terraform-apply`: Apply changes

## Common Commands

### Terraform Commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Initialize Terraform (run in terraform/src/repository/)
cd terraform/src/repository
terraform init -upgrade

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes (usually done via GitHub Actions)
terraform apply -auto-approve

# Import existing repository
terraform import module.<module_name>.github_repository.this <repo_name>
```

### Linting Commands

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Run specific hooks
pre-commit run terraform_fmt --all-files
pre-commit run yamllint --all-files
pre-commit run markdownlint --all-files

# TFLint for Terraform
tflint --init
tflint --chdir=terraform/src/repository --call-module-type=all
```

### Development Commands

```bash
# Install pre-commit hooks
pre-commit install

# Set common GitHub secrets across repositories
./scripts/set-common-github-secrets.sh <github_owner>
```

## Adding a New Repository

1. Create a new `.tf` file in `terraform/src/repository/` (e.g., `my-new-repo.tf`)
2. Use this pattern:

```hcl
module "my_new_repo" {
  source = "../../modules/repository"

  github_token    = var.github_token
  repository      = "my-new-repo"
  description     = "Repository description"
  default_branch  = "main"
  topics          = ["terraform", "automation"]

  branches_to_protect = {
    main = {
      required_status_checks         = true
      required_pull_request_reviews  = true
      dismiss_stale_reviews          = true
      require_code_owner_reviews     = true
      required_approving_review_count = 1
    }
  }
}
```

## Environment Requirements

- Terraform version: 1.12.2 (see `.terraform-version`)
- AWS credentials for S3 backend (via OIDC in GitHub Actions)
- GitHub App credentials or PAT token
- Pre-commit installed for local development

## Key Workflows

### PR Workflow

1. Create feature branch
2. Make changes to `.tf` files
3. Push branch and create PR
4. GitHub Actions runs `terraform plan` and comments on PR
5. After approval and merge, `terraform apply` runs automatically

### Import Existing Repository

1. Go to Actions tab → "Terraform Import" workflow
2. Run with parameters:
   - `module`: module name (e.g., `my_repo`)
   - `repo`: GitHub repository name
3. Workflow imports repository, default branch, actions permissions, and branch protection

## State Management

- Terraform state is stored in AWS S3 with DynamoDB for locking
- Each environment has its own state file
- Backend configuration is in `terraform/src/repository/terraform.tf`

## Security Considerations

- GitHub tokens are managed as secrets in GitHub Actions
- AWS authentication uses OIDC (no long-lived credentials)
- Pre-commit hooks detect private keys and AWS credentials
- Branch protection enforces code review requirements
