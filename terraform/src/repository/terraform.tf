terraform {
  required_version = "1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.8.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "terraform-github/terraform/src/repository.tfstate"
    region  = "ap-northeast-1"
  }
}

moved {
  from = module.local_workspace_provisioning.github_repository.this
  to   = module.local-workspace-provisioning.github_repository.this
}
moved {
  from = module.local_workspace_provisioning.github_branch_default.this
  to   = module.local-workspace-provisioning.github_branch_default.this
}
moved {
  from = module.local_workspace_provisioning.github_actions_repository_permissions.this
  to   = module.local-workspace-provisioning.github_actions_repository_permissions.this
}
moved {
  from = module.local_workspace_provisioning.github_branch_protection.this["main"]
  to   = module.local-workspace-provisioning.github_branch_protection.this["main"]
}

moved {
  from = module.anime_tweet_bot.github_repository.this
  to   = module.anime-tweet-bot.github_repository.this
}
moved {
  from = module.anime_tweet_bot.github_branch_default.this
  to   = module.anime-tweet-bot.github_branch_default.this
}
moved {
  from = module.anime_tweet_bot.github_actions_repository_permissions.this
  to   = module.anime-tweet-bot.github_actions_repository_permissions.this
}
moved {
  from = module.anime_tweet_bot.github_branch_protection.this["main"]
  to   = module.anime-tweet-bot.github_branch_protection.this["main"]
}

moved {
  from = module.openai_generate_pr_description.github_repository.this
  to   = module.openai-generate-pr-description.github_repository.this
}
moved {
  from = module.openai_generate_pr_description.github_branch_default.this
  to   = module.openai-generate-pr-description.github_branch_default.this
}
moved {
  from = module.openai_generate_pr_description.github_actions_repository_permissions.this
  to   = module.openai-generate-pr-description.github_actions_repository_permissions.this
}
moved {
  from = module.openai_generate_pr_description.github_branch_protection.this["main"]
  to   = module.openai-generate-pr-description.github_branch_protection.this["main"]
}

moved {
  from = module.boilerplate_saas.github_repository.this
  to   = module.boilerplate-saas.github_repository.this
}
moved {
  from = module.boilerplate_saas.github_branch_default.this
  to   = module.boilerplate-saas.github_branch_default.this
}
moved {
  from = module.boilerplate_saas.github_actions_repository_permissions.this
  to   = module.boilerplate-saas.github_actions_repository_permissions.this
}
moved {
  from = module.boilerplate_saas.github_branch_protection.this["main"]
  to   = module.boilerplate-saas.github_branch_protection.this["main"]
}

moved {
  from = module.time_capsule.github_repository.this
  to   = module.time-capsule.github_repository.this
}
moved {
  from = module.time_capsule.github_branch_default.this
  to   = module.time-capsule.github_branch_default.this
}
moved {
  from = module.time_capsule.github_actions_repository_permissions.this
  to   = module.time-capsule.github_actions_repository_permissions.this
}
moved {
  from = module.time_capsule.github_branch_protection.this["main"]
  to   = module.time-capsule.github_branch_protection.this["main"]
}

moved {
  from = module.terraform_vercel.github_repository.this
  to   = module.terraform-vercel.github_repository.this
}
moved {
  from = module.terraform_vercel.github_branch_default.this
  to   = module.terraform-vercel.github_branch_default.this
}
moved {
  from = module.terraform_vercel.github_actions_repository_permissions.this
  to   = module.terraform-vercel.github_actions_repository_permissions.this
}
moved {
  from = module.terraform_vercel.github_branch_protection.this["main"]
  to   = module.terraform-vercel.github_branch_protection.this["main"]
}

moved {
  from = module.terraform_github.github_repository.this
  to   = module.terraform-github.github_repository.this
}
moved {
  from = module.terraform_github.github_branch_default.this
  to   = module.terraform-github.github_branch_default.this
}
moved {
  from = module.terraform_github.github_actions_repository_permissions.this
  to   = module.terraform-github.github_actions_repository_permissions.this
}
moved {
  from = module.terraform_github.github_branch_protection.this["main"]
  to   = module.terraform-github.github_branch_protection.this["main"]
}

moved {
  from = module.terraform_aws.github_repository.this
  to   = module.terraform-aws.github_repository.this
}
moved {
  from = module.terraform_aws.github_branch_default.this
  to   = module.terraform-aws.github_branch_default.this
}
moved {
  from = module.terraform_aws.github_actions_repository_permissions.this
  to   = module.terraform-aws.github_actions_repository_permissions.this
}
moved {
  from = module.terraform_aws.github_branch_protection.this["main"]
  to   = module.terraform-aws.github_branch_protection.this["main"]
}

moved {
  from = module.renovate_config.github_repository.this
  to   = module.renovate-config.github_repository.this
}
moved {
  from = module.renovate_config.github_branch_default.this
  to   = module.renovate-config.github_branch_default.this
}
moved {
  from = module.renovate_config.github_actions_repository_permissions.this
  to   = module.renovate-config.github_actions_repository_permissions.this
}
moved {
  from = module.renovate_config.github_branch_protection.this["main"]
  to   = module.renovate-config.github_branch_protection.this["main"]
}

moved {
  from = module.obsidian_vault.github_repository.this
  to   = module.obsidian-vault.github_repository.this
}
moved {
  from = module.obsidian_vault.github_branch_default.this
  to   = module.obsidian-vault.github_branch_default.this
}
moved {
  from = module.obsidian_vault.github_actions_repository_permissions.this
  to   = module.obsidian-vault.github_actions_repository_permissions.this
}
moved {
  from = module.obsidian_vault.github_branch_protection.this["main"]
  to   = module.obsidian-vault.github_branch_protection.this["main"]
}

moved {
  from = module.private_dotfiles.github_repository.this
  to   = module.private-dotfiles.github_repository.this
}
moved {
  from = module.private_dotfiles.github_branch_default.this
  to   = module.private-dotfiles.github_branch_default.this
}
moved {
  from = module.private_dotfiles.github_actions_repository_permissions.this
  to   = module.private-dotfiles.github_actions_repository_permissions.this
}
moved {
  from = module.private_dotfiles.github_branch_protection.this["main"]
  to   = module.private-dotfiles.github_branch_protection.this["main"]
}
