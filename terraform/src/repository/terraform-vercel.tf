module "terraform-vercel" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-vercel"
  default_branch = "main"
  topics         = ["terraform", "vercel"]
  description    = "Configure Vercel resources with Terraform."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}
