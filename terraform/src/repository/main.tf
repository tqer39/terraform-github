module "tqer39" {
  source = "../../modules/repository"

  repository     = "tqer39"
  default_branch = "main"
  topics         = ["profile"]
  description    = "personal information repository"

  branches_to_protect = {
    "main" = {
      require_pull_request_reviews = true
      required_status_checks       = true
    }
  }
}
