moved {
  from = module.dotfiles.github_actions_repository_permissions.this
  to   = module.dotfiles.github_actions_repository_permissions.this[0]
}

module "dotfiles" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "dotfiles"
  default_branch = "main"
  description    = "My dotfiles repository"
  visibility     = "public"

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = []
    }
  }
}
