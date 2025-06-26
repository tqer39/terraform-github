moved {
  from = module.terraform-vercel.github_actions_repository_permissions.this
  to   = module.terraform-vercel.github_actions_repository_permissions.this[0]
}

module "terraform-vercel" {
  source              = "../../modules/repository"
  github_token        = var.github_token
  repository          = "terraform-vercel"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["terraform", "vercel"]
  description         = "Configure Vercel resources with Terraform."
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
