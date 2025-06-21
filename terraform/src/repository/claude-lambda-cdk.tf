module "claude_lambda_cdk" {
  source                 = "../../modules/repository"
  github_token           = var.github_token
  owner                  = "AIPairStudio"
  repository             = "claude-lambda-cdk"
  default_branch         = "main"
  topics                 = ["aws", "cdk", "lambda", "typescript", "serverless"]
  description            = "AWS CDK project for deploying Lambda functions with best practices"
  homepage_url           = ""
  visibility             = "private"
  has_issues             = true
  has_projects           = true
  has_wiki               = false
  allow_auto_merge       = true
  allow_update_branch    = true
  delete_branch_on_merge = true

  # Temporarily disable actions permissions configuration to avoid 404 error
  # Enable this after the repository is created
  configure_actions_permissions = false

  # Use new branch rulesets instead of traditional branch protection
  branch_rulesets = {
    "Protect main branch" = {
      target      = "branch"
      enforcement = "active"

      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"] # Protects 'main' branch
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
            { context = "terraform-plan" },
            { context = "cdk-build" },
            { context = "cdk-test" }
          ]
          strict = true # Require branches to be up to date before merging
        }

        # Branch protection settings
        deletion                = false # Prevent branch deletion
        non_fast_forward        = false # Prevent force pushes
        required_linear_history = true  # Require linear history
        required_signatures     = false # Don't require signed commits for now
      }

      # Allow specific actors to bypass rules if needed
      bypass_actors = [
        # Example: Allow bots to bypass
        # {
        #   actor_id    = "123456"  # Renovate bot ID
        #   actor_type  = "App"
        #   bypass_mode = "pull_request"  # Only bypass for PRs
        # }
      ]
    }
  }
}
