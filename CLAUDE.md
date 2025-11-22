# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform Infrastructure as Code (IaC) project that manages GitHub repositories using Terraform and GitHub Actions. The repository uses a modular architecture to automate the creation, configuration, and protection of multiple GitHub repositories.

## Architecture

### Module-Based Design

The codebase clearly separates reusable modules from repository-specific configurations:

- **`terraform/modules/repository/`**: Core reusable Terraform module for GitHub repository management
  - `github_repository.tf`: Repository creation and configuration
  - `github_branch_protection.tf`: Traditional branch protection (legacy, being phased out)
  - `github_repository_ruleset.tf`: Modern repository rulesets (recommended approach)
  - `github_actions_repository_permissions.tf`: GitHub Actions permission management
  - `github_branch.tf` & `github_branch_default.tf`: Branch creation and default branch management

- **`terraform/src/repository/`**: Repository-specific configurations
  - Each `.tf` file represents a single GitHub repository
  - Uses the core module with repository-specific parameters
  - `terraform.tf`: Backend configuration with S3 state storage
  - `moved` blocks indicate refactoring from underscore to hyphen naming convention

### CI/CD Integration

- **`.github/workflows/`**: GitHub Actions workflows
  - `terraform-github.yml`: Main workflow for plan/apply (PR-triggered)
  - `terraform-import.yml`: Import existing repositories
  - `prek.yml`: Code quality checks

- **`.github/actions/`**: Reusable action components
  - `setup-terraform`: Initialization and format checking
  - `terraform-validate`: Validation and linting
  - `terraform-plan`: Planning with PR comments via tfcmt
  - `terraform-apply`: Change application with deployment tracking

## Common Commands

### Initial Setup

```bash
# Install all required tools
make bootstrap

# Setup development environment
just setup

# Verify installation
just check-tools
```

### Terraform Operations

```bash
# Format all Terraform files
just fmt

# Initialize Terraform
just init

# Validate configuration
just validate

# Plan changes
just plan

# Apply changes (primarily done via GitHub Actions, use with caution locally)
just apply

# Import existing repository resources
cd terraform/src/repository
terraform import module.<module_name>.github_repository.this <repo_name>
terraform import module.<module_name>.github_branch_default.this <repo_name>
terraform import module.<module_name>.github_actions_repository_permissions.this <repo_name>
terraform import module.<module_name>.github_branch_protection.this[\"<branch_name>\"] <repo_name>:<branch_name>
```

### Code Quality

```bash
# Run all prek hooks
just lint

# Run specific hooks
just lint-hook terraform_fmt
just lint-hook terraform_validate
just lint-hook terraform_tflint
just lint-hook yamllint
just lint-hook markdownlint

# Fix common issues
just fix

# Format staged files
just fmt-staged
```

### Git Worktree

```bash
# Interactive worktree setup
just worktree-setup

# Manual worktree management
git worktree add ../terraform-github-<branch-name> -b <branch-name>
git worktree list
git worktree remove ../terraform-github-<branch-name>
```

### Repository Management

```bash
# Set common secrets across repositories
./scripts/set-common-github-secrets.sh <github_owner>
```

### Maintenance

```bash
# Clean Terraform temporary files
just clean

# Show versions
just version

# Show mise-managed tool versions
just status

# Install tools from .tool-versions
just install

# Update mise-managed tools
just update

# Update brew packages
just update-brew
```

## Adding New Repositories

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

  # Modern repository rulesets (recommended)
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

1. Create a feature branch and modify repository configurations
2. Push the branch and create a PR
3. GitHub Actions automatically:
   - Acquire AWS credentials via OIDC
   - Generate GitHub App token (or use PAT for personal repos)
   - Run `terraform plan` using tfcmt and post as PR comment
   - Post plan results as PR comment
4. After merge to main:
   - Same authentication flow
   - Automatically run `terraform apply`
   - Track deployment status

### Importing Existing Repositories

1. Go to Actions tab → "Terraform Import" workflow
2. Click "Run workflow" with parameters:
   - `module`: Module name (e.g., `my_repo`)
   - `repo`: GitHub repository name
3. Workflow imports:
   - Repository configuration
   - Default branch
   - Actions permissions
   - Branch protection rules

## Authentication Strategy

The project supports multiple authentication methods:

- **GitHub App tokens**: For organization repositories (recommended)
- **Personal Access Tokens (PAT)**: For personal repositories (`TERRAFORM_GITHUB_TOKEN`)
- **GitHub Actions tokens**: Standard `GITHUB_TOKEN` for workflow operations
- **AWS OIDC**: Temporary credentials for S3 backend (no long-term keys)

## State Management

- Backend: AWS S3 with DynamoDB locking
- State file: `terraform/src/repository/terraform.tfstate`
- Configuration: `terraform/src/repository/terraform.tf`
- Migration: Handled by `moved` blocks for refactoring

## Security Considerations

- All tokens managed as GitHub Actions secrets
- AWS authentication via OIDC (no static credentials)
- Pre-commit hooks detect secrets and private keys
- Branch protection enforces code review
- Repository rulesets provide granular access control

## Module Parameter Reference

Key parameters for the repository module:

- `repository`: Repository name (required)
- `owner`: Organization name (optional, defaults to personal account)
- `description`: Repository description
- `visibility`: `public` or `private`
- `default_branch`: Default branch name (usually `main`)
- `topics`: List of repository topics/tags
- `branch_rulesets`: Modern rule-based protection (recommended)
- `branches_to_protect`: Legacy branch protection (backward compatibility)
- `has_wiki`, `has_issues`, `has_projects`: Feature toggles
- `allow_merge_commit`, `allow_squash_merge`, `allow_rebase_merge`: Merge strategies

## Documentation Structure and Guidelines

### Document File Organization

- **Project Root** (`*.md`): English documentation
  - `README.md`: Project overview (English)
  - `CONTRIBUTING.md`: Contribution guidelines (English)
  - `CHANGELOG.md`: Change history (English)
  - `CLAUDE.md`: AI assistant guidance (English)

- **Japanese Documentation** (`./docs/*.ja.md`): Japanese documentation
  - `./docs/README.ja.md`: Project overview (Japanese)
  - `./docs/CONTRIBUTING.ja.md`: Contribution guidelines (Japanese)
  - `./docs/architecture.ja.md`: Architecture details (Japanese)
  - `./docs/troubleshooting.ja.md`: Troubleshooting (Japanese)

### Processing Directory for Document Creation

1. **English Documentation**: Place in project root
2. **Japanese Documentation**: Place in `./docs/` directory with `.ja.md` extension
3. **Multi-language Support**: Create locale-specific subdirectories within `./docs/` as needed

### Documentation Management Best Practices

- Use English as the standard for main project documentation
- Japanese documentation serves a complementary role within `./docs/`
- Maintain clear and consistent file naming
- Keep corresponding language versions synchronized when updating

### Development Diary

- **Purpose**: Record major changes and their rationale, document technical decisions and implementation details, track issues encountered and solutions, and provide context for future developers
- **Creation Rules**:
  - Create a new diary entry when there are uncommitted changes or undocumented work from previous commits
  - File naming follows format: `docs/dev-diary/YYYY-MM-DD.md`
  - Automatically create a file if one for today's date doesn't exist
  - Document all development work since the last diary entry
- **Format Requirements**: Each diary entry should include:
  - Overview of work
  - Implementation details
  - Test results
  - Issues and solutions
  - Future considerations
  - Developer's mood and reflections
  - Potential refactoring opportunities
- **Timing**: Create the diary entry at the end of a development session or when requested

## Coding Standards and Conventions

### Terraform/HCL Style

- Use 2-space indentation
- Always run `terraform fmt` before committing (enforced by prek hooks)
- Follow HashiCorp's official style guide

### Naming Conventions

- **Directory/Module names**: Use kebab-case (e.g., `local-workspace-provisioning`)
- **Variable/Resource names**: Use snake_case (e.g., `repository_ruleset`)
- **File organization**: Split by functionality (e.g., `variables.tf`, `provider.tf`, `main.tf`)

### File Structure

- `terraform/src/repository/`: Stack definitions (one `*.tf` file per repository)
- `terraform/modules/repository/`: Reusable modules for repository management

## Testing and Validation

- Primary "tests" are `terraform validate` and `terraform plan`
- PRs must include a summary of plan output (additions/changes/destructions)
- Destructive changes must be clearly marked with the application method (GitHub Actions or manual)
- Validation command: `terraform -chdir=terraform/src/repository validate`
- Plan command: `terraform -chdir=terraform/src/repository plan`
- With AWS authentication: `aws-vault exec portfolio -- terraform -chdir=terraform/src/repository plan`

## Commit and PR Guidelines

- Follow **Conventional Commits** format: `feat:`, `fix:`, `chore:`, `refactor:`, etc.
- PRs must include:
  - Purpose and scope
  - Affected repositories/rules
  - Related issues
  - Summary of `terraform plan` output
- Keep changes small and focused
- No screenshots needed (use plan logs instead)

## Important Instruction Reminders

### General Guidelines

- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User

### Agent-Specific Guidelines

- Do not introduce unrelated changes or formatting differences
- Strictly follow existing layout and naming conventions
- All changes in `terraform/src/repository/` must be validated with `terraform plan`
- Include plan summary in PR descriptions
- When making Terraform changes:
  1. Read existing code first to understand patterns
  2. Make minimal, focused changes
  3. Run `terraform validate` and `terraform plan`
  4. Document the changes and their impact

## Repository Deletion Process

- Use `aws-vault exec portfolio` to obtain appropriate AWS credentials and remove resources/modules from Terraform tfstate.
- `portfolio` is the AWS profile name for the SSO role configured in `~/.aws/config`.

```shell
aws-vault exec portfolio -- terraform -chdir=./terraform/src/repository state rm  module.sample-repository
Removed module.sample-repository.data.github_user.tqer39
Removed module.sample-repository.github_actions_repository_permissions.this[0]
Removed module.sample-repository.github_branch_default.this
Removed module.sample-repository.github_repository.this
Successfully removed 4 resource instance(s).
```

- Delete the related source code `terraform/src/repository/sample-repository.tf`.
- Delete the GitHub repository.

```shell
gh repo delete tqer39/sample-repository --confirm
```
