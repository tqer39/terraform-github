module "this" {
  source                          = "../../../modules/repository"
  github_token                    = var.github_token
  repository                      = "setup-develop-environments"
  owner                           = "tqer39"
  default_branch                  = "main"
  description                     = "Setup develop environments repository"
  visibility                      = "private"
  archived                        = true
  disable_default_main_protection = true
}
