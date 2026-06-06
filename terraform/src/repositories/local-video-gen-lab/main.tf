module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "local-video-gen-lab"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "private"
  description         = "Playground for evaluating local LLM / diffusion models for video generation."
  topics = [
    "video-generation",
    "local-llm",
    "ai",
    "playground",
  ]
}
