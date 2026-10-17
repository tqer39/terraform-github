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
    condition     = alltrue([for environment in github_repository_environment.release : !environment.can_admins_bypass])
    error_message = "管理者のEnvironment迂回は無効にしてください。"
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
