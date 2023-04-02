module "tqer39" {
  source = "../../modules/repository"

  default_branch = "main"
  repository     = "tqer39"
  topics         = ["managed-by-terraform-github"]

  branches_to_protect = {
    "main" = {
      require_pull_request_reviews    = true
      required_approving_review_count = 1
      dismiss_stale_reviews           = false
      require_code_owner_reviews      = false
      restrict_dismissals             = false
      dismissal_restrictions          = []
      required_status_checks          = true
      status_check_up_to_date         = true
      status_check_contexts           = []
      require_signed_commits          = false
      enforce_admins                  = false
      push_restrictions               = []
      allows_deletions                = false
      allows_force_pushes             = false
      required_linear_history         = false
    }
  }
}
