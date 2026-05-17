module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "claude-code-marketplace"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["claude-code", "marketplace"]
  description         = "Claude Code Marketplace."
}
