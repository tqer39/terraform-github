module "terraform_github" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-github"
  default_branch = "main"
  topics         = ["terraform", "github"]
  description    = "Configure GitHub resources with Terraform."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit", "terraform-github"]
    }
  }
}
