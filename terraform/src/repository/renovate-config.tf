module "renovate_config" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "renovate-config"
  default_branch = "main"
  topics         = ["renovate"]
  description    = "Renovate Configuration."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
