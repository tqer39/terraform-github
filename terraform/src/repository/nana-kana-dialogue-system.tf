moved {
  from = module.nana-kana-dialogue-system.github_actions_repository_permissions.this
  to   = module.nana-kana-dialogue-system.github_actions_repository_permissions.this[0]
}

module "nana_kana_dialogue_system" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "nana-kana-dialogue-system"
  default_branch = "main"
  visibility     = "private"
  topics = [
    "3d-animation",
    "ai-content",
    "blender",
    "content-generation",
    "dialogue-system",
    "fastapi",
    "ghost-cms",
    "javascript",
    "python",
    "react",
    "text-to-speech",
    "three-js",
    "typescript"
  ]
  description  = "女子高生ナナと社会人カナによる対話型コンテンツ制作システム - 3D Animation + TTS + Ghost CMS"
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
