moved {
  from = module.boilerplate-saas.github_actions_repository_permissions.this
  to   = module.boilerplate-saas.github_actions_repository_permissions.this[0]
}

module "boilerplate-saas" {
  source       = "../../modules/repository"
  github_token = var.github_token

  repository          = "boilerplate-saas"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["boilerplate"]
  description         = "A boilerplate for SaaS applications"

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
      }
    }
  }
}
