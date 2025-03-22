module "blog" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "blog"
  default_branch = "main"
  topics         = ["blog"]
  description    = "Configure blog resources with Terraform."
  homepage_url   = "https://blog-tqer39s-projects.vercel.app"
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}
