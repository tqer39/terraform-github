module "this" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "nana-kana-dialogue-system"
  owner          = "tqer39"
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
  description         = "女子高生ナナと社会人カナによる対話型コンテンツ制作システム - 3D Animation + TTS + Ghost CMS"
  has_projects        = true
  has_issues          = true
  has_wiki            = false
  enable_owner_bypass = true
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
    "development" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["refs/heads/development"]
          exclude = []
        }
      }
      rules = {}
    }
  }
}
