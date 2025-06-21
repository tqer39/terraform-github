# GitHub Repository Rulesets

This module now supports GitHub Repository Rulesets, which provide more flexible and powerful branch protection than traditional branch protection rules.

## Usage Example

```hcl
module "my_repo" {
  source       = "../../modules/repository"
  github_token = var.github_token
  owner        = "AIPairStudio"
  repository   = "claude-lambda-cdk"
  # ... other configuration ...

  # Define repository rulesets
  branch_rulesets = {
    "Protect main branch" = {
      target      = "branch"
      enforcement = "active"

      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]  # Matches the default branch (main)
          exclude = []
        }
      }

      rules = {
        # Require pull request before merging
        pull_request = {
          require_code_owner_review         = false
          require_last_push_approval        = true
          dismiss_stale_reviews_on_push     = true
          required_approving_review_count   = 1
          required_review_thread_resolution = true
        }

        # Require status checks
        required_status_checks = {
          required_checks = [
            { context = "pre-commit" },
            { context = "terraform-plan" }
          ]
          strict = true
        }

        # Branch protection settings
        deletion                = false      # Prevent branch deletion
        non_fast_forward        = false      # Prevent force pushes
        required_linear_history = true       # Require linear history
        required_signatures     = false      # Require signed commits
      }

      # Optional: Allow specific actors to bypass rules
      bypass_actors = [
        # {
        #   actor_id   = "123456"  # User or team ID
        #   actor_type = "Team"    # "User", "Team", or "App"
        #   bypass_mode = "always" # "always" or "pull_request"
        # }
      ]
    }
  }
}
```

## Key Features

### 1. Flexible Targeting
- Target specific branches using patterns
- Include/exclude specific refs

### 2. Comprehensive Rules
- **Pull Request Requirements**: Review counts, code owner reviews, thread resolution
- **Status Checks**: Required CI/CD checks with strict mode
- **Branch Protection**: Prevent deletion, force pushes, require linear history
- **Commit Patterns**: Enforce commit message, author email, or branch name patterns

### 3. Bypass Options
- Allow specific users, teams, or apps to bypass rules
- Configure bypass mode (always or only for pull requests)

## Advantages Over Traditional Branch Protection

1. **More Granular Control**: Target multiple branches with patterns
2. **Better Organization**: Group related rules together
3. **Flexible Bypass**: More options for who can bypass and when
4. **Enhanced Security**: More rule types available

## Migration from Branch Protection

To migrate from `branches_to_protect` to `branch_rulesets`:

```hcl
# Old way
branches_to_protect = {
  "main" = {
    required_status_checks        = true
    required_pull_request_reviews = true
  }
}

# New way with rulesets
branch_rulesets = {
  "Protect main branch" = {
    target      = "branch"
    enforcement = "active"
    conditions = {
      ref_name = {
        include = ["~DEFAULT_BRANCH"]
      }
    }
    rules = {
      pull_request = {
        required_approving_review_count = 1
      }
      required_status_checks = {
        required_checks = []
        strict = true
      }
    }
  }
}
```
