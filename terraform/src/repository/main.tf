module "time_capsule" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "time-capsule"
  default_branch = "main"
  topics         = ["time-capsule", "nextjs"]
  description    = "Create a time capsule repository."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
