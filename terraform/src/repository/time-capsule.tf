moved {
  from = module.time-capsule.github_actions_repository_permissions.this
  to   = module.time-capsule.github_actions_repository_permissions.this[0]
}

module "time-capsule" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "time-capsule"
  default_branch = "main"
  topics         = ["time-capsule", "nextjs"]
  description    = "A service that sends account information to a trusted person when you pass away"
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
