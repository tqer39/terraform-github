module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "update-license-year"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["license"]
  description         = "Automatically update license year in repositories."
}
