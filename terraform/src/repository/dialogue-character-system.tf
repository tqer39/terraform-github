module "dialogue_character_system" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "dialogue-character-system"
  organization   = "AIPairStudio"
  default_branch = "main"
  visibility     = "private"
  topics = [
    "3d-animation",
    "ai-content",
    "character-system",
    "dialogue-generation",
    "fastapi",
    "llm",
    "python",
    "react",
    "text-to-speech",
    "typescript",
    "voice-synthesis"
  ]
  description  = "Generic dialogue character system for creating interactive AI character conversations with 3D animation and voice synthesis"
  has_projects = true
  has_issues   = true
  has_wiki     = false
  branches_to_protect = {
    "main" = {
      required_status_checks          = true
      required_pull_request_reviews   = true
      dismiss_stale_reviews           = true
      require_code_owner_reviews      = false
      required_approving_review_count = 1
    }
    "development" = {
      required_status_checks        = false
      required_pull_request_reviews = false
    }
  }
}
