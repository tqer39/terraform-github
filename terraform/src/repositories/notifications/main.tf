module "this" {
  source                 = "../../../modules/repository"
  github_token           = var.github_token
  repository             = "notifications"
  owner                  = "tqer39"
  default_branch         = "main"
  enable_owner_bypass    = true
  topics                 = ["notifications", "api"]
  description            = "A repository for managing notification services."
  delete_branch_on_merge = true
}
