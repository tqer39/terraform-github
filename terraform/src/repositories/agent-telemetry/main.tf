module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "agent-telemetry"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "public"
  topics              = ["observability", "opentelemetry", "grafana", "docker-compose", "claude-code", "codex"]
  description         = "Local observability for Claude Code / Claude Desktop and Codex CLI / Codex Desktop (OTLP + transcript summaries)."

  # dev-standards.yml の standards-check はすべての PR で動くため、必須チェックに加える。
  default_main_protection_additional_required_checks = ["standards-check"]
}

# CI の App installation token は個人アカウントにリポジトリを作成できないため、先に作成したものを取り込む。
import {
  to = module.this.github_repository.this[0]
  id = "agent-telemetry"
}
