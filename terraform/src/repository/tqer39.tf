module "tqer39" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "tqer39"
  default_branch = "main"
  topics         = ["profile"]
  description    = "personal information repository"

  branches_to_protect = {
    "main" = {
      # GitHub Action のワークフローで main に push するために必要
      allows_force_pushes           = true
      required_pull_request_reviews = true
    }
  }
}
