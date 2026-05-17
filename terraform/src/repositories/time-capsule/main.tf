module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "time-capsule"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["time-capsule", "nextjs"]
  description         = "A service that sends account information to a trusted person when you pass away"
}
