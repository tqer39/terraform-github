terraform {
  required_version = "1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.13.0"
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

moved {
  from = module.ed-games.github_repository.this_from_template[0]
  to   = module.mathquest.github_repository.this_from_template[0]
}
moved {
  from = module.ed-games.github_branch_default.this
  to   = module.mathquest.github_branch_default.this
}
moved {
  from = module.ed-games.github_repository_ruleset.this["main"]
  to   = module.mathquest.github_repository_ruleset.this["main"]
}

# Move addresses after splitting github_repository into count-based resources
moved {
  from = module.anime-tweet-bot.github_repository.this
  to   = module.anime-tweet-bot.github_repository.this[0]
}
moved {
  from = module.blender_chat_character.github_repository.this
  to   = module.blender_chat_character.github_repository.this[0]
}
moved {
  from = module.blog.github_repository.this
  to   = module.blog.github_repository.this[0]
}
moved {
  from = module.boilerplate-base.github_repository.this
  to   = module.boilerplate-base.github_repository.this[0]
}
moved {
  from = module.boilerplate-saas.github_repository.this
  to   = module.boilerplate-saas.github_repository.this[0]
}
moved {
  from = module.dotfiles.github_repository.this
  to   = module.dotfiles.github_repository.this[0]
}
moved {
  from = module.local-workspace-provisioning.github_repository.this
  to   = module.local-workspace-provisioning.github_repository.this[0]
}
moved {
  from = module.my-chat-ai-comfyui.github_repository.this
  to   = module.my-chat-ai-comfyui.github_repository.this[0]
}
moved {
  from = module.nana_kana_dialogue_system.github_repository.this
  to   = module.nana_kana_dialogue_system.github_repository.this[0]
}
moved {
  from = module.notifications.github_repository.this
  to   = module.notifications.github_repository.this[0]
}
moved {
  from = module.obsidian-vault.github_repository.this
  to   = module.obsidian-vault.github_repository.this[0]
}
moved {
  from = module.openai-generate-pr-description.github_repository.this
  to   = module.openai-generate-pr-description.github_repository.this[0]
}
moved {
  from = module.private-dotfiles.github_repository.this
  to   = module.private-dotfiles.github_repository.this[0]
}
moved {
  from = module.renovate-config.github_repository.this
  to   = module.renovate-config.github_repository.this[0]
}
moved {
  from = module.terraform-aws.github_repository.this
  to   = module.terraform-aws.github_repository.this[0]
}
moved {
  from = module.terraform-github.github_repository.this
  to   = module.terraform-github.github_repository.this[0]
}
moved {
  from = module.terraform-vercel.github_repository.this
  to   = module.terraform-vercel.github_repository.this[0]
}
moved {
  from = module.time-capsule.github_repository.this
  to   = module.time-capsule.github_repository.this[0]
}
moved {
  from = module.tqer39.github_repository.this
  to   = module.tqer39.github_repository.this[0]
}
moved {
  from = module.update-license-year.github_repository.this
  to   = module.update-license-year.github_repository.this[0]
}
