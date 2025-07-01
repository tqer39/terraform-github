module "notifications" {
  source                 = "../../modules/repository"
  github_token           = var.github_token
  repository             = "notifications"
  owner                  = "tqer39"
  default_branch         = "main"
  enable_owner_bypass    = true
  topics                 = ["notifications", "api"]
  description            = "A repository for managing notification services."
  visibility             = "private"
  delete_branch_on_merge = true
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
