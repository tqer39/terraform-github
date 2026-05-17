module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "boilerplate-saas"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["boilerplate"]
  description         = "A boilerplate for SaaS applications"
}
