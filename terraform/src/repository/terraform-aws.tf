moved {
  from = module.terraform-aws.github_actions_repository_permissions.this
  to   = module.terraform-aws.github_actions_repository_permissions.this[0]
}

module "terraform-aws" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-aws"
  default_branch = "main"
  topics         = ["terraform", "aws"]
  description    = "Configure AWS resources with Terraform."
  branch_rulesets = {
    "main" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]
          exclude = []
        }
      }
      rules = {
        pull_request = {
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = false
          required_approving_review_count   = 1
          required_review_thread_resolution = true
        }
        required_status_checks = {
          required_check = [
            {
              context = "pre-commit"
            },
            {
              context = "terraform-aws-management"
            },
            {
              context = "terraform-aws-portfolio"
            },
            {
              context = "terraform-aws-sandbox"
            }
          ]
          strict_required_status_checks_policy = true
        }
      }
    }
  }
}
