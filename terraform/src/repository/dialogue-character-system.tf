module "dialogue_character_system" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "dialogue-character-system"
  owner          = "AIPairStudio"
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
  description         = "Generic dialogue character system for creating interactive AI character conversations with 3D animation and voice synthesis"
  has_projects        = true
  has_issues          = true
  has_wiki            = false
  enable_owner_bypass = true
  branch_rulesets = {
    "main" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }
      rules = {
        pull_request = {
          required_approving_review_count = 1
          dismiss_stale_reviews_on_push   = true
          require_code_owner_review       = false
        }
        required_status_checks = {
          strict_required_status_checks_policy = true
          required_checks                      = []
        }
        deletion                = false
        non_fast_forward        = false
        required_linear_history = false
      }
    }
    "development" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["refs/heads/development"]
          exclude = []
        }
      }
      rules = {
        deletion         = false
        non_fast_forward = false
      }
    }
  }
}
