module "tqer39" {
  source = "../../modules/repository"

  repository     = "tqer39"
  default_branch = "main"
  topics         = ["profile"]
  description    = "personal information repository"

  branches_to_protect = {
    "main" = {
      # GitHub Action のワークフローで main に push するために必要
      allows_force_pushes = true
    }
  }
}

module "renovate_config" {
  source = "../../modules/repository"

  repository     = "renovate-config"
  default_branch = "main"
  topics         = ["renovate"]
  description    = "Renovate Configuration."

  branches_to_protect = {
    "main" = {
      required_pull_request_reviews   = true
      required_approving_review_count = 1
      required_status_checks          = true
    }
  }
}

module "terraform_aws" {
  source = "../../modules/repository"

  repository     = "terraform-aws"
  default_branch = "main"
  topics         = ["aws"]
  description    = "Configure AWS resources with Terraform."

  branches_to_protect = {
    "main" = {
      required_pull_request_reviews   = true
      required_approving_review_count = 1
      required_status_checks          = true
    }
  }
}
