module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "agent-worktree-cli"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["ai-agents", "cli", "git-worktree", "claude-code", "codex", "cursor"]
  description         = "Shared Git worktree launcher for AI coding agents"
  visibility          = "public"
}
