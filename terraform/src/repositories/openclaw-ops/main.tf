module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "openclaw-ops"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  allow_merge_commit  = false
  allow_squash_merge  = true
  allow_rebase_merge  = false
  topics              = ["openclaw", "ops"]
  description         = "Configuration and operations repository for OpenClaw."

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
