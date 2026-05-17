module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "renovate-config"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["renovate"]
  description         = "Renovate Configuration."
}
