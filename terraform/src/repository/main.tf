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

module "renovate_config" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "renovate-config"
  default_branch = "main"
  topics         = ["renovate"]
  description    = "Renovate Configuration."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
      status_check_contexts         = ["pre-commit"]
    }
  }
}

module "terraform_aws" {
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

module "terraform_vercel" {
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

module "blog" {
  source         = "../../modules/repository"
  github_token   = var.github_token
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

import {
  id = openai_generate_pr_description
  to = module.openai_generate_pr_description.github_repository.this
}

import {
  id = openai_generate_pr_description
  to = module.openai_generate_pr_description.github_branch_default.this
}

import {
  id = openai_generate_pr_description
  to = module.openai_generate_pr_description.github_branch_protection.this["main"]
}

import {
  id = openai_generate_pr_description
  to = module.openai_generate_pr_description.github_repository.this
}
