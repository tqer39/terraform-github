module "dotfiles" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "dotfiles"
  default_branch = "main"
  description    = "My dotfiles repository"
  visibility     = "private" # 必要に応じて "public" も可

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = []
    }
  }
}
