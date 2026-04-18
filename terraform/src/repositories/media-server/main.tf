module "this" {
  source                          = "../../../modules/repository"
  github_token                    = var.github_token
  repository                      = "media-server"
  owner                           = "tqer39"
  default_branch                  = "main"
  enable_owner_bypass             = true
  disable_default_main_protection = true # TODO: 段階移行後に削除（PR #1555 follow-up）
  visibility                      = "private"
  topics                          = ["docker", "docker-compose", "ubuntu-server", "jellyfin", "komga", "audiobookshelf", "homelab"]
  description                     = "Ubuntu Server media stack with Docker Compose for LAN streaming (Jellyfin, Komga, Audiobookshelf)."

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
