# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Overview

Terraform IaC project managing GitHub repositories via modular architecture and GitHub Actions automation.

## Key Paths

| Path | Purpose |
| ---- | ------- |
| `terraform/modules/repository/` | Reusable Terraform module (repository, branch protection, rulesets, actions permissions) |
| `terraform/src/repository/` | Repository-specific configs (one `.tf` file per repo) |
| `.github/workflows/` | CI/CD: `terraform-github.yml` (plan/apply), `terraform-import.yml`, `prek.yml` |
| `.github/actions/` | Reusable actions: setup-terraform, terraform-validate, terraform-plan, terraform-apply |

## Quick Commands

| Task | Command |
| ---- | ------- |
| Setup | `make bootstrap && just setup` |
| Format | `just fmt` |
| Validate | `just validate` |
| Plan | `just plan` |
| Lint | `just lint` |
| Clean | `just clean` |

For detailed commands (import, worktree, maintenance, deletion): see `.claude/docs/commands-reference.md`

## Adding Repositories

1. Create `terraform/src/repository/<repo-name>.tf`
2. Use module from `../../modules/repository` with required parameters
3. Run `just validate && just plan`
4. Create PR for review

For HCL patterns (modern rulesets vs legacy branch protection): see `.claude/docs/terraform-patterns.md`

## PR Workflow

1. Create feature branch, modify configs
2. Push and create PR -> GitHub Actions runs `terraform plan`, posts as comment
3. After merge to main -> auto `terraform apply`

## Authentication

- **GitHub App tokens**: Organization repos (recommended)
- **PAT**: Personal repos (`TERRAFORM_GITHUB_TOKEN`)
- **AWS OIDC**: S3 backend (no static credentials)

## State Management

Backend: AWS S3 with DynamoDB locking. Migration via `moved` blocks.

## Module Parameters

Key parameters: `repository` (required), `owner`, `description`, `visibility`, `default_branch`, `topics`, `branch_rulesets` (recommended), `branches_to_protect` (legacy)

Full reference: see `.claude/docs/terraform-patterns.md`

## Coding Standards

### Naming Conventions

- **Directories/Modules**: kebab-case (e.g., `local-workspace-provisioning`)
- **Variables/Resources**: snake_case (e.g., `repository_ruleset`)

### HCL Style

- 2-space indentation
- Always run `terraform fmt` before committing
- Follow HashiCorp style guide

## Validation

```bash
just validate                    # Validate configuration
just plan                        # Plan changes (shows additions/changes/destructions)
aws-vault exec portfolio -- just plan  # With AWS auth
```

PRs must include plan output summary. Destructive changes must be clearly marked.

## Commit Guidelines

Follow **Conventional Commits**: `feat:`, `fix:`, `chore:`, `refactor:`, etc.

PRs must include: purpose/scope, affected repos/rules, related issues, plan summary.

## Critical Instructions

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files over creating new ones
- NEVER proactively create documentation files unless explicitly requested
- Read existing code first to understand patterns before making changes
- Make minimal, focused changes
- All changes in `terraform/src/repository/` must be validated with `terraform plan`

## References

- Detailed commands: `.claude/docs/commands-reference.md`
- HCL patterns: `.claude/docs/terraform-patterns.md`
- Documentation guidelines: `.claude/docs/documentation-guidelines.md`
