mock_provider "github" {}

variables {
  github_token                    = "test-token"
  repository                      = "test-repository"
  disable_default_main_protection = true
  configure_actions_permissions   = false
}

run "unmanaged_default" {
  command = plan

  assert {
    condition     = length(local.security_and_analysis) == 0
    error_message = "未指定のリポジトリでは security_and_analysis を管理しないこと。"
  }
}

run "enabled" {
  command = plan

  variables {
    secret_scanning                 = true
    secret_scanning_push_protection = true
  }

  assert {
    condition = (
      github_repository.this[0].security_and_analysis[0].secret_scanning[0].status == "enabled" &&
      github_repository.this[0].security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled"
    )
    error_message = "secret scanning と push protection を有効にすること。"
  }
}
