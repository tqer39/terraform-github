module "terraform-aws" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-aws"
  default_branch = "main"
  topics         = ["terraform", "aws"]
  description    = "Configure AWS resources with Terraform."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit", "terraform-aws-management", "terraform-aws-portfolio", "terraform-aws-sandbox"]
    }
  }
}
