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

module "openai_generate_pr_description" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "openai-generate-pr-description"
  default_branch = "main"
  topics         = ["openai"]
  description    = "Generate Pull Request description with OpenAI."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}
