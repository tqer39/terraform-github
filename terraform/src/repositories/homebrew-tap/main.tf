module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository                      = "homebrew-tap"
  owner                           = "tqer39"
  default_branch                  = "main"
  enable_owner_bypass             = true
  disable_default_main_protection = true # 下の branch_rulesets["main"] でカスタム定義するため
  description                     = "Homebrew tap for tqer39 tools (ccw-cli など)"
  visibility                      = "public"
  topics = [
    "homebrew",
    "homebrew-tap",
    "formula",
  ]

  # goreleaser (GitHub App) が Formula/*.rb を直接 push できるように
  # App を bypass actor に登録したカスタム main 保護を定義する。
  # required_status_checks は tap に CI が無いので外す。
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
        deletion                = true
        non_fast_forward        = true
        required_linear_history = true
        pull_request = {
          required_approving_review_count   = 0
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = false
          required_review_thread_resolution = true
        }
      }
      bypass_actors = [
        {
          actor_id    = tonumber(var.gha_app_id)
          actor_type  = "Integration"
          bypass_mode = "always"
        },
      ]
    }
  }
}
