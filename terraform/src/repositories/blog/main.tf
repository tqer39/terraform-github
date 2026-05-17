module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "blog"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  allow_merge_commit  = false
  allow_squash_merge  = true
  allow_rebase_merge  = false
  topics              = ["blog"]
  description         = "Personal blog monorepo powered by Next.js, Hono, and Cloudflare."
  homepage_url        = "https://blog.tqer39.dev"
}
