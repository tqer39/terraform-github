module "tqer39" {
  source = "../../modules/repository"

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

module "renovate_config" {
  source = "../../modules/repository"

  repository     = "renovate-config"
  default_branch = "main"
  topics         = ["renovate"]
  description    = "Renovate Configuration."

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
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
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}

module "terraform_github" {
  source = "../../modules/repository"

  repository     = "terraform-github"
  default_branch = "main"
  topics         = ["github"]
  description    = "Configure GitHub resources with Terraform."

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit", "terraform-github"]
    }
  }
}

module "terraform_vercel" {
  source = "../../modules/repository"

  repository     = "terraform-vercel"
  default_branch = "main"
  topics         = ["vercel"]
  description    = "Configure Vercel resources with Terraform."

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}

module "blog" {
  source = "../../modules/repository"

  repository     = "blog"
  default_branch = "main"
  topics         = ["blog"]
  description    = "Configure blog resources with Terraform."

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}

module "time_capsule" {
  source         = "../../modules/repository"
  repository     = "time-capsule"
  default_branch = "main"
  topics         = ["time-capsule"]
  description    = "Create a time capsule repository."

  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}
