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
