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
