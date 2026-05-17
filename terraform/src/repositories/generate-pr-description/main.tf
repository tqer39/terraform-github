module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "generate-pr-description"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = []
  description         = "Generate Pull Request description."
}
