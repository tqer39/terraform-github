mock_provider "github" {}

variables {
  github_token                    = "test-token"
  repository                      = "test-repository"
  disable_default_main_protection = true
}

run "active_default" {
  command = plan

  assert {
    condition     = github_actions_repository_permissions.this[0].enabled
    error_message = "既存リポジトリでは Actions を既定で有効にすること。"
  }
}

run "retired_repository" {
  command = plan

  variables {
    archived        = true
    actions_enabled = false
  }

  assert {
    condition     = !github_actions_repository_permissions.this[0].enabled && github_actions_repository_permissions.this[0].allowed_actions == null
    error_message = "撤去するリポジトリでは Actions を再度有効化しないこと。"
  }
}
