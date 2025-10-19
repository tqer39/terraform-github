module "edu-quest" {
  source       = "../../modules/repository"
  github_token = var.github_token

  repository          = "edu-quest"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "Repository generated from boilerplate-base template"
  # 新規作成時の Plan で 404 を避けるため、最初は false 推奨
  configure_actions_permissions = false

  # Create from template
  template_owner                = "tqer39"
  template_repository           = "boilerplate-base"
  template_include_all_branches = false

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
        required_status_checks = {
          required_check = [
            {
              context = "prek"
            }
          ]
          strict_required_status_checks_policy = true
        }
      }
    }
  }
}
