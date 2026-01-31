module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "Style-Bert-VITS2"
  owner               = "tqer39"
  default_branch      = "master"
  enable_owner_bypass = true
  description         = "Style-Bert-VITS2: Text to Speech model"

  # フォーク設定
  fork         = true
  source_owner = "litagin02"
  source_repo  = "Style-Bert-VITS2"

  branch_rulesets = {
    "master" = {
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
