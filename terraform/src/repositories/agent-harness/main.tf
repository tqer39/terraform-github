module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "agent-harness"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "public"
  topics              = ["claude-code", "codex", "ai-agents", "orca"]
  description         = "承認済みの GitHub Issue から、Codex の実装、Claude のレビュー、マージまでを進めるエージェントハーネス"
}

# CI の App installation token は個人アカウントにリポジトリを作成できないため、先に作成したものを取り込む。
import {
  to = module.this.github_repository.this[0]
  id = "agent-harness"
}
