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
}
