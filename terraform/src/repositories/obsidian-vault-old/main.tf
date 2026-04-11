module "this" {
  source                 = "../../../modules/repository"
  github_token           = var.github_token
  repository             = "obsidian-vault-old"
  owner                  = "tqer39"
  default_branch         = "main"
  enable_owner_bypass    = true
  topics                 = ["obsidian", "vault", "docs", "archived"]
  description            = "Archived. Superseded by obsidian-vault."
  visibility             = "private"
  delete_branch_on_merge = true
  archived               = true
  branch_rulesets        = {}
}
