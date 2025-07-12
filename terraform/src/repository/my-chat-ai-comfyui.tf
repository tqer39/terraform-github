module "my-chat-ai-comfyui" {
  source              = "../../modules/repository"
  github_token        = var.github_token
  repository          = "my-chat-ai-comfyui"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["comfyui", "chat-ai"]
  description         = "Integrate chat AI features with ComfyUI"
  visibility          = "private"
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
