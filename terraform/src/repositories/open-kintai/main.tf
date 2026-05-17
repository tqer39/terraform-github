module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "open-kintai"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  allow_merge_commit  = false
  allow_squash_merge  = true
  allow_rebase_merge  = false
  description         = "open-kintai"
  topics              = ["open-kintai"]
}
