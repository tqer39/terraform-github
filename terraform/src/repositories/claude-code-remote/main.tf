module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "claude-code-remote"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "private"
  topics = [
    "claude-code",
    "remote-orchestration",
    "fastapi",
    "discord-bot",
    "cloudflare-tunnel",
    "pwa",
  ]
  description = "Remote orchestration system for Claude Code across multiple machines via FastAPI, Discord Bot, and Cloudflare Tunnel."
}
