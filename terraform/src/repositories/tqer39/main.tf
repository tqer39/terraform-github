module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "tqer39"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["profile"]
  description         = "personal information repository"
}
