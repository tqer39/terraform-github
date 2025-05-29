module "private_dotfiles" {
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
