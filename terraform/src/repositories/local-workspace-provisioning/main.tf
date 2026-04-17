module "this" {
  source                          = "../../../modules/repository"
  github_token                    = var.github_token
  repository                      = "local-workspace-provisioning"
  owner                           = "tqer39"
  default_branch                  = "main"
  description                     = "Local workspace provisioning repository."
  archived                        = true
  visibility                      = "private"
  disable_default_main_protection = true
}
