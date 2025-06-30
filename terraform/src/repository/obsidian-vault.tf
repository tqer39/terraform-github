moved {
  from = module.obsidian-vault.github_actions_repository_permissions.this
  to   = module.obsidian-vault.github_actions_repository_permissions.this[0]
}

module "obsidian-vault" {
  source                 = "../../modules/repository"
  github_token           = var.github_token
  repository             = "obsidian-vault"
  owner                  = "tqer39"
  default_branch         = "main"
  enable_owner_bypass    = true
  topics                 = ["obsidian", "vault", "docs"]
  description            = "A repository for managing Obsidian Vault configurations."
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
