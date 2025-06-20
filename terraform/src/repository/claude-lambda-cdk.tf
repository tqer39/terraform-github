module "claude_lambda_cdk" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "claude-lambda-cdk"
  default_branch = "main"
  topics         = ["aws", "cdk", "lambda", "typescript", "serverless"]
  description    = "AWS CDK project for deploying Lambda functions with best practices"
  homepage_url   = ""
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
  owner                = "AIPairStudio"
  visibility           = "private"
  has_issues           = true
  has_projects         = true
  has_wiki             = false
  has_downloads        = true
  has_discussions      = false
  allow_merge_commit   = true
  allow_squash_merge   = true
  allow_rebase_merge   = true
  allow_update_branch  = true
  allow_forking        = false
  delete_branch_on_merge = true
}
