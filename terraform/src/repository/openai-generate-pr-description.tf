moved {
  from = module.openai-generate-pr-description.github_actions_repository_permissions.this
  to   = module.openai-generate-pr-description.github_actions_repository_permissions.this[0]
}

module "openai-generate-pr-description" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "openai-generate-pr-description"
  default_branch = "main"
  topics         = ["openai"]
  description    = "Generate Pull Request description with OpenAI."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
