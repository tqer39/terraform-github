module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "repos-context"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  allow_merge_commit  = false
  allow_squash_merge  = true
  allow_rebase_merge  = false
  topics              = ["repos-context"]
  description         = "Provides contextual information for AI assistants working with repositories."
}
