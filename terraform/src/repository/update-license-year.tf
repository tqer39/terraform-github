moved {
  from = module.update-license-year.github_actions_repository_permissions.this
  to   = module.update-license-year.github_actions_repository_permissions.this[0]
}

module "update-license-year" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "update-license-year"
  default_branch = "main"
  topics         = ["license"]
  description    = "Automatically update license year in repositories."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
