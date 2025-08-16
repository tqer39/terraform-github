module "blender_chat_character" {
  source              = "../../modules/repository"
  github_token        = var.github_token
  repository          = "blender-chat-character"
  owner               = "tqer39"
  default_branch      = "main"
  visibility          = "public"
  enable_owner_bypass = true
  topics = [
    "3d-animation",
    "blender",
    "character-animation",
    "chat-interface",
    "python",
    "real-time-animation"
  ]
  description  = "Interactive 3D character animation system with chat interface using Blender"
  has_projects = false
  has_issues   = true
  has_wiki     = false
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
