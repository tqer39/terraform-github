mock_provider "github" {}
override_resource {
  target = github_workflow_repository_permissions.security_updates
  values = { id = "kazokubi" }
}
override_module {
  target  = module.this
  outputs = {}
}
variables {
  github_token        = "test-token"
  discord_webhook_url = "https://discord.com/api/webhooks/123456789012345678/example-token"
}
run "separate_release_environments" {
  command = plan
  assert {
    condition     = toset(keys(github_repository_environment.release)) == toset(["dev", "production"])
    error_message = "Devと本番は別のEnvironmentにしてください。"
  }
  assert {
    condition     = alltrue([for policy in github_repository_environment_deployment_policy.release : policy.branch_pattern == "main"])
    error_message = "承認用Actionsはmainだけを許可してください。"
  }
  assert {
    condition = alltrue([for environment in github_repository_environment.release :
      environment.can_admins_bypass &&
      !environment.deployment_branch_policy[0].protected_branches &&
      environment.deployment_branch_policy[0].custom_branch_policies
    ])
    error_message = "private Pro の API 実値を管理し、実効性のある main 限定ポリシーを維持してください。"
  }
  assert {
    condition = (
      github_repository_ruleset.release_tags.enforcement == "active" &&
      github_repository_ruleset.release_tags.target == "tag" &&
      github_repository_ruleset.release_tags.conditions[0].ref_name[0].include == tolist(["refs/tags/v*"]) &&
      github_repository_ruleset.release_tags.rules[0].deletion &&
      github_repository_ruleset.release_tags.rules[0].update
    )
    error_message = "公開タグの上書き・削除を禁止してください。"
  }
}
run "security_update_pull_requests" {
  command = plan
  assert {
    condition = (
      github_workflow_repository_permissions.security_updates.repository == "kazokubi" &&
      github_workflow_repository_permissions.security_updates.default_workflow_permissions == "read" &&
      github_workflow_repository_permissions.security_updates.can_approve_pull_request_reviews
    )
    error_message = "既定の読み取り権限を維持し、kazokubi の自動更新 PR 作成を許可してください。"
  }
}
run "explicit_environment_secrets" {
  command = plan
  variables {
    discord_webhook_url = "https://discord.com/api/webhooks/123456789012345678/example-token"
    release_secrets = {
      dev        = { TURSO_AUTH_TOKEN = "test-dev", DB_BACKUP_KEY = "test-dev-key" }
      production = { TURSO_AUTH_TOKEN = "test-production", DB_BACKUP_KEY = "test-production-key" }
    }
  }
  assert {
    condition     = length(github_actions_environment_secret.release) == 4 && github_actions_environment_secret.release["dev/TURSO_AUTH_TOKEN"].environment != github_actions_environment_secret.release["production/TURSO_AUTH_TOKEN"].environment
    error_message = "資格情報を環境ごとのSecretへ保存してください。"
  }
}
run "reject_unexpected_environment" {
  command = plan
  variables {
    release_secrets = { staging = { TURSO_AUTH_TOKEN = "test-token" } }
  }
  expect_failures = [var.release_secrets]
}

run "reject_missing_webhook" {
  command = plan
  variables {
    discord_webhook_url = ""
  }
  expect_failures = [var.discord_webhook_url]
}


run "trusted_actions_only" {
  command = plan
  assert {
    condition = (
      github_actions_repository_permissions.trusted_actions.enabled &&
      github_actions_repository_permissions.trusted_actions.allowed_actions == "selected" &&
      github_actions_repository_permissions.trusted_actions.sha_pinning_required &&
      !github_actions_repository_permissions.trusted_actions.allowed_actions_config[0].github_owned_allowed &&
      !github_actions_repository_permissions.trusted_actions.allowed_actions_config[0].verified_allowed &&
      github_actions_repository_permissions.trusted_actions.allowed_actions_config[0].patterns_allowed == toset([
        "1password/load-secrets-action@*", "actions/checkout@*", "actions/create-github-app-token@*",
        "actions/download-artifact@*", "actions/setup-node@*", "actions/upload-artifact@*",
        "aws-actions/configure-aws-credentials@*", "jdx/mise-action@*", "kentaro-m/auto-assign-action@*",
      ])
    )
    error_message = "SHA 固定と必要な Action だけの許可を維持してください。"
  }
}
