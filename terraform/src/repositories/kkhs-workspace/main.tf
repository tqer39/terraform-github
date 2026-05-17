module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "kkhs-workspace"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "kkhs workspace repository"
  visibility          = "private"
}
