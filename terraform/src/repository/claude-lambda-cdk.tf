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

  # Use traditional branch protection
  branches_to_protect = {
    "main" = {
      required_status_checks          = true
      required_pull_request_reviews   = true
      status_check_contexts           = [
        "pre-commit",
        "terraform-plan",
        "cdk-build",
        "cdk-test"
      ]
      dismiss_stale_reviews           = true
      required_approving_review_count = 1
      require_last_push_approval      = true
    }
  }
}
