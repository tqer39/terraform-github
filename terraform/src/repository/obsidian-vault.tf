moved {
  from = module.obsidian-vault.github_actions_repository_permissions.this
  to   = module.obsidian-vault.github_actions_repository_permissions.this[0]
}

module "obsidian-vault" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "obsidian-vault"
  default_branch = "main"
  topics         = ["obsidian", "vault", "docs"]
  description    = "A repository for managing Obsidian Vault configurations."
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
