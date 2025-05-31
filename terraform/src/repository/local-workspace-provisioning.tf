module "local-workspace-provisioning" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "local-workspace-provisioning"
  default_branch = "main"
  description    = "Local workspace provisioning repository."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
