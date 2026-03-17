module "this" {
  source                 = "../../../modules/repository"
  github_token           = var.github_token
  repository             = "obsidian-vault-2"
  owner                  = "tqer39"
  default_branch         = "main"
  enable_owner_bypass    = true
  topics                 = ["obsidian", "vault", "docs"]
  description            = "A repository for managing Obsidian Vault configurations."
  visibility             = "private"
  delete_branch_on_merge = true
  branch_rulesets        = {}
}
