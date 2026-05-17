module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "xtrade"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "XTrade - Trading platform and analysis tools"
  topics = [
    "trading",
    "finance",
    "typescript",
    "terraform",
  ]
  configure_actions_permissions = false

  template_owner                = "tqer39"
  template_repository           = "boilerplate-base"
  template_include_all_branches = false
}
