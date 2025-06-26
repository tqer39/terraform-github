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
          require_code_owner_review         = false
          required_approving_review_count   = 1
          required_review_thread_resolution = true
        }
        required_status_checks = {
          required_check = [
            {
              context = "pre-commit"
            }
          ]
          strict_required_status_checks_policy = true
        }
      }
    }
  }
}
