module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "agent-foundry"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "private"
  description         = "LLM agent orchestration foundry: Founder Agent, Agent Factory, and agent organization design."
  topics = [
    "ai-agents",
    "multi-agent",
    "llm",
    "agent-orchestration",
    "founder-agent",
  ]
}
