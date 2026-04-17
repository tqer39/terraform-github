module "this" {
  source                          = "../../../modules/repository"
  github_token                    = var.github_token
  repository                      = "obsidian-vault-old"
  owner                           = "tqer39"
  default_branch                  = "main"
  topics                          = ["obsidian", "vault", "docs", "archived"]
  description                     = "Archived. Superseded by obsidian-vault."
  visibility                      = "private"
  delete_branch_on_merge          = true
  archived                        = true
  disable_default_main_protection = true
}
