# Commands Reference

Detailed command reference for terraform-github repository operations.

## Initial Setup

```bash
make bootstrap       # Install all required tools
just setup           # Setup development environment
just check-tools     # Verify installation
```

## Terraform Operations

| Command | Description |
| ------- | ----------- |
| `just fmt` | Format all Terraform files |
| `just init` | Initialize Terraform |
| `just validate` | Validate configuration |
| `just plan` | Plan changes |
| `just apply` | Apply changes (use with caution locally) |

### Import Existing Repository

```bash
cd terraform/src/repository
terraform import module.<module_name>.github_repository.this <repo_name>
terraform import module.<module_name>.github_branch_default.this <repo_name>
terraform import module.<module_name>.github_actions_repository_permissions.this <repo_name>
terraform import module.<module_name>.github_branch_protection.this[\"<branch_name>\"] <repo_name>:<branch_name>
```

### Import via GitHub Actions

1. Go to Actions tab -> "Terraform Import" workflow
2. Click "Run workflow" with parameters:
   - `module`: Module name (e.g., `my_repo`)
   - `repo`: GitHub repository name
3. Workflow imports: repository config, default branch, actions permissions, branch protection

## Code Quality

| Command | Description |
| ------- | ----------- |
| `just lint` | Run all prek hooks |
| `just lint-hook <hook>` | Run specific hook (terraform_fmt, terraform_validate, terraform_tflint, yamllint, markdownlint) |
| `just fix` | Fix common issues |
| `just fmt-staged` | Format staged files |

## Git Worktree

```bash
just worktree-setup                                    # Interactive setup
git worktree add ../terraform-github-<branch> -b <branch>  # Manual add
git worktree list                                      # List worktrees
git worktree remove ../terraform-github-<branch>      # Remove worktree
```

## Maintenance

| Command | Description |
| ------- | ----------- |
| `just clean` | Clean Terraform temporary files |
| `just version` | Show versions |
| `just status` | Show mise-managed tool versions |
| `just install` | Install tools from .tool-versions |
| `just update` | Update mise-managed tools |
| `just update-brew` | Update brew packages |

## Repository Deletion Process

1. Remove from Terraform state using AWS credentials:

```bash
aws-vault exec portfolio -- terraform -chdir=./terraform/src/repository state rm module.<repo-name>
```

Note: `portfolio` is the AWS profile name for the SSO role configured in `~/.aws/config`.

1. Delete the source file: `terraform/src/repository/<repo-name>.tf`

2. Delete the GitHub repository:

```bash
gh repo delete <owner>/<repo-name> --confirm
```

## Repository Secrets

```bash
./scripts/set-common-github-secrets.sh <github_owner>
```
