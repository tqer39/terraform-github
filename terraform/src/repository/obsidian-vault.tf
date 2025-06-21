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
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
