module "this" {
  source                 = "../../../modules/repository"
  github_token           = var.github_token
  repository             = "obsidian-vault"
  owner                  = "tqer39"
  default_branch         = "main"
  enable_owner_bypass    = true
  topics                 = ["obsidian", "vault", "docs"]
  description            = "A repository for managing Obsidian Vault configurations."
  visibility             = "private"
  delete_branch_on_merge = true
  branch_rulesets        = {}

  # tqer39-obsidian-vault-writer の App ID（Installation ID ではない）
  default_main_protection_bypass_app_ids = [4916965]
}
