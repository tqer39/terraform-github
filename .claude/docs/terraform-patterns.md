# Terraform Patterns

HCL patterns for repository configuration. For real examples, see existing files in `terraform/src/repository/`.

## Modern Approach (Repository Rulesets) - Recommended

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

## Legacy Approach (Branch Protection)

```hcl
module "my_legacy_repo" {
  source = "../../modules/repository"

  github_token    = var.github_token
  repository      = "my-legacy-repo"
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

## Key Module Parameters

| Parameter | Required | Description |
| --------- | -------- | ----------- |
| `repository` | Yes | Repository name |
| `owner` | No | Organization name (defaults to personal account) |
| `description` | No | Repository description |
| `visibility` | No | `public` or `private` |
| `default_branch` | No | Default branch name (usually `main`) |
| `topics` | No | List of repository topics/tags |
| `branch_rulesets` | No | Modern rule-based protection (recommended) |
| `branches_to_protect` | No | Legacy branch protection |
| `has_wiki`, `has_issues`, `has_projects` | No | Feature toggles |
| `allow_merge_commit`, `allow_squash_merge`, `allow_rebase_merge` | No | Merge strategies |
