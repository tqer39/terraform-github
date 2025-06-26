moved {
  from = module.private-dotfiles.github_actions_repository_permissions.this
  to   = module.private-dotfiles.github_actions_repository_permissions.this[0]
}

module "private-dotfiles" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "private-dotfiles"
  default_branch = "main"
  description    = "My private dotfiles repository"
  visibility     = "private"

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
