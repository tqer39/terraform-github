module "this" {
  source                          = "../../../modules/repository"
  github_token                    = var.github_token
  repository                      = "claude-code-remote"
  owner                           = "tqer39"
  default_branch                  = "main"
  enable_owner_bypass             = true
  disable_default_main_protection = true # TODO: 段階移行後に削除（PR #1555 follow-up）
  visibility                      = "private"
  topics = [
    "claude-code",
    "remote-orchestration",
    "fastapi",
    "discord-bot",
    "cloudflare-tunnel",
    "pwa",
  ]
  description = "Remote orchestration system for Claude Code across multiple machines via FastAPI, Discord Bot, and Cloudflare Tunnel."

  branch_rulesets = {
    "main" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]
          exclude = []
        }
      }
      rules = {
        pull_request = {
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = false
          required_approving_review_count   = 1
          required_review_thread_resolution = true
        }
      }
    }
  }
}
