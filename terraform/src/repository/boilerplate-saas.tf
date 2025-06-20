moved {
  from = module.boilerplate-saas.github_actions_repository_permissions.this
  to   = module.boilerplate-saas.github_actions_repository_permissions.this[0]
}

module "boilerplate-saas" {
  source       = "../../modules/repository"
  github_token = var.github_token

  repository     = "boilerplate-saas"
  default_branch = "main"
  topics         = ["boilerplate"]
  description    = "A boilerplate for SaaS applications"

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}
