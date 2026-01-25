module "this" {
  source              = "../../modules/repository"
  github_token        = var.github_token
  repository          = "setup-develop-environments"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "Setup develop environments repository"
  visibility          = "private"
  archived            = true
}
