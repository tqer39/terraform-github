module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "dotfiles"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "My dotfiles repository"
  visibility          = "public"

  environments = {
    "claude-autofix" = {
      prevent_self_review = true
      reviewers = {
        users = ["tqer39"]
      }
    }
  }
}
