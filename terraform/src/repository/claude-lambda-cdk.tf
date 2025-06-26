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
  enable_owner_bypass    = true

  # Temporarily disable actions permissions configuration to avoid 404 error
  # Enable this after the repository is created
  configure_actions_permissions = false

  branch_rulesets = {
    "main" = {
      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }
      rules = {
        # Require pull requests before merging
        pull_request = {
          required_approving_review_count = 1
          dismiss_stale_reviews_on_push   = true
          require_last_push_approval      = true
        }
        # Require status checks to pass before merging
        required_status_checks = {
          strict_required_status_checks_policy = false
          required_checks                      = []
        }
        # Require linear history
        required_linear_history = true
      }
    }
  }
}
