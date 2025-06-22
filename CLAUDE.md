# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform Infrastructure as Code (IaC) project for managing GitHub repositories using Terraform and GitHub Actions. The repository automates the creation, configuration, and protection of multiple GitHub repositories using a modular architecture.

## Architecture

### Module-Based Design

The codebase follows a clean separation between reusable modules and repository-specific configurations:

- **`terraform/modules/repository/`**: Core reusable Terraform module for GitHub repository management
  - `github_repository.tf`: Creates and configures repositories
  - `github_branch_protection.tf`: Traditional branch protection (legacy, being phased out)
  - `github_repository_ruleset.tf`: Modern repository rulesets (preferred approach)
  - `github_actions_repository_permissions.tf`: Manages GitHub Actions permissions
  - `github_branch.tf` & `github_branch_default.tf`: Branch creation and default branch management

- **`terraform/src/repository/`**: Repository-specific configurations
  - Each `.tf` file represents a single GitHub repository
  - Uses the core module with repository-specific parameters
  - `terraform.tf`: Backend configuration with S3 state storage
  - `moved` blocks indicate recent refactoring from underscore to hyphen naming

### CI/CD Integration

- **`.github/workflows/`**: GitHub Actions workflows
  - `terraform-github.yml`: Main workflow for plan/apply (PR-triggered)
  - `terraform-import.yml`: Import existing repositories
  - `pre-commit.yml`: Code quality checks

- **`.github/actions/`**: Reusable action components
  - `setup-terraform`: Initialize and format check
  - `terraform-validate`: Validation and linting
  - `terraform-plan`: Plan with tfcmt PR comments
  - `terraform-apply`: Apply changes with deployment tracking

## Common Commands

### Terraform Operations

```bash
# Format all Terraform files
terraform fmt -recursive

# Initialize Terraform (must be run in terraform/src/repository/)
cd terraform/src/repository
terraform init -upgrade

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes (primarily done via GitHub Actions)
terraform apply -auto-approve

# Import existing repository resources
terraform import module.<module_name>.github_repository.this <repo_name>
terraform import module.<module_name>.github_branch_default.this <repo_name>
terraform import module.<module_name>.github_actions_repository_permissions.this <repo_name>
terraform import module.<module_name>.github_branch_protection.this[\"<branch_name>\"] <repo_name>:<branch_name>
```

### Code Quality

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Run specific hooks
pre-commit run terraform_fmt --all-files
pre-commit run terraform_validate --all-files
pre-commit run terraform_tflint --all-files
pre-commit run yamllint --all-files
pre-commit run markdownlint --all-files

# TFLint with module support
tflint --init
tflint --chdir=terraform/src/repository --call-module-type=all
```

### Repository Management

```bash
# Set common secrets across repositories
./scripts/set-common-github-secrets.sh <github_owner>
```

## Adding a New Repository

1. Create a new `.tf` file in `terraform/src/repository/` (e.g., `my-new-repo.tf`)
2. Use the appropriate pattern based on your needs:

### Modern Approach (Repository Rulesets)

```hcl
module "my_new_repo" {
  source = "../../modules/repository"

  github_token    = var.github_token
  repository      = "my-new-repo"
  owner           = "AIPairStudio"  # Optional: organization name
  description     = "Repository description"
  default_branch  = "main"
  visibility      = "public"  # or "private"
  topics          = ["terraform", "automation"]

  # Modern repository rulesets (preferred)
  branch_rulesets = {
    "main" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]
          exclude = []
        }
      }
      rules = {
        pull_request = {
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = true
          required_approving_review_count   = 1
          required_review_thread_resolution = true
        }
      }
    }
  }
}
```

### Legacy Approach (Branch Protection)

```hcl
module "my_legacy_repo" {
  source = "../../modules/repository"

  github_token    = var.github_token
  repository      = "my-legacy-repo"
  description     = "Repository description"
  default_branch  = "main"
  topics          = ["terraform", "automation"]

  # Legacy branch protection (still supported)
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

## Key Workflows

### Pull Request Workflow

1. Create feature branch and modify repository configurations
2. Push branch and create PR
3. GitHub Actions automatically:
   - Obtains AWS credentials via OIDC
   - Generates GitHub App token (or uses PAT for personal repos)
   - Runs `terraform plan` with tfcmt for PR comments
   - Posts plan results as PR comment
4. After merge to main:
   - Same authentication flow
   - Automatically runs `terraform apply`
   - Tracks deployment status

### Import Existing Repository

1. Navigate to Actions tab → "Terraform Import" workflow
2. Click "Run workflow" with parameters:
   - `module`: module name (e.g., `my_repo`)
   - `repo`: GitHub repository name
3. Workflow imports:
   - Repository configuration
   - Default branch
   - Actions permissions
   - Branch protection rules

## Authentication Strategy

The project supports multiple authentication methods:

- **GitHub App Token**: For organization repositories (preferred)
- **Personal Access Token (PAT)**: For personal repositories (`TERRAFORM_GITHUB_TOKEN`)
- **GitHub Actions Token**: Standard `GITHUB_TOKEN` for workflow operations
- **AWS OIDC**: Temporary credentials for S3 backend (no long-lived keys)

## State Management

- Backend: AWS S3 with DynamoDB locking
- State file: `terraform/src/repository/terraform.tfstate`
- Configuration: `terraform/src/repository/terraform.tf`
- Migration: Handled via `moved` blocks for refactoring

## Security Considerations

- All tokens managed as GitHub Actions secrets
- AWS authentication via OIDC (no static credentials)
- Pre-commit hooks detect secrets and private keys
- Branch protection enforces code review
- Repository rulesets provide fine-grained access control

## Module Parameters Reference

Key parameters for the repository module:

- `repository`: Repository name (required)
- `owner`: Organization name (optional, defaults to personal account)
- `description`: Repository description
- `visibility`: `public` or `private`
- `default_branch`: Default branch name (typically `main`)
- `topics`: List of repository topics/tags
- `branch_rulesets`: Modern rule-based protection (recommended)
- `branches_to_protect`: Legacy branch protection (backward compatibility)
- `has_wiki`, `has_issues`, `has_projects`: Feature toggles
- `allow_merge_commit`, `allow_squash_merge`, `allow_rebase_merge`: Merge strategies
