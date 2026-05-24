module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "personal-ai-assistant"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "private"
  description         = "Personal assistant AI for executing harness engineering workflows."
  topics = [
    "ai-assistant",
    "automation",
    "harness-engineering",
    "personal-assistant",
    "secretary-ai",
  ]
}
