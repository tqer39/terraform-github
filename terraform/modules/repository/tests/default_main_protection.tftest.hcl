mock_provider "github" {}

variables {
  github_token = "test-token"
  repository   = "test-repository"
}

run "default_protection" {
  command = plan

  assert {
    condition = toset(github_repository_ruleset.default_main_protection[0].bypass_actors) == toset([{
      actor_id    = 5
      actor_type  = "RepositoryRole"
      bypass_mode = "pull_request"
    }])
    error_message = "既定では所有者の PR 経由の bypass だけを許可すること。"
  }
}

run "app_bypass_preserves_protection" {
  command = plan

  variables {
    default_main_protection_bypass_app_ids = [4916965]
  }

  assert {
    condition = toset(github_repository_ruleset.default_main_protection[0].bypass_actors) == toset([
      { actor_id = 5, actor_type = "RepositoryRole", bypass_mode = "pull_request" },
      { actor_id = 4916965, actor_type = "Integration", bypass_mode = "always" },
    ])
    error_message = "所有者の bypass を維持し、指定した App だけに常時 bypass を追加すること。"
  }

  assert {
    condition = alltrue([
      github_repository_ruleset.default_main_protection[0].rules[0].deletion,
      github_repository_ruleset.default_main_protection[0].rules[0].non_fast_forward,
      github_repository_ruleset.default_main_protection[0].rules[0].required_linear_history,
      github_repository_ruleset.default_main_protection[0].rules[0].pull_request[0].required_approving_review_count == 0,
      one(github_repository_ruleset.default_main_protection[0].rules[0].required_status_checks[0].required_check).context == "workflow-result",
    ])
    error_message = "App の bypass 追加で保護ルールを変更しないこと。"
  }
}

run "app_bypass_without_owner" {
  command = plan

  variables {
    default_main_protection_owner_bypass   = false
    default_main_protection_bypass_app_ids = [4916965]
  }

  assert {
    condition = toset(github_repository_ruleset.default_main_protection[0].bypass_actors) == toset([{
      actor_id    = 4916965
      actor_type  = "Integration"
      bypass_mode = "always"
    }])
    error_message = "所有者の bypass を無効にしても、App の bypass は独立して設定できること。"
  }
}
