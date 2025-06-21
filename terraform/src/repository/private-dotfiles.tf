moved {
  from = module.private-dotfiles.github_actions_repository_permissions.this
  to   = module.private-dotfiles.github_actions_repository_permissions.this[0]
}

module "private-dotfiles" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "private-dotfiles"
  default_branch = "main"
  description    = "My private dotfiles repository"
  visibility     = "private"

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = []
    }
  }
}
