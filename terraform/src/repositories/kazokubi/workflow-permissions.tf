resource "github_workflow_repository_permissions" "security_updates" {
  repository                       = "kazokubi"
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true

  depends_on = [module.this]
}

import {
  to = github_workflow_repository_permissions.security_updates
  id = "kazokubi"
}


# SHA 固定の強制を含む設定を、このリポジトリの管理範囲にまとめる。
moved {
  from = module.this.github_actions_repository_permissions.this[0]
  to   = github_actions_repository_permissions.trusted_actions
}

resource "github_actions_repository_permissions" "trusted_actions" {
  repository           = "kazokubi"
  enabled              = true
  allowed_actions      = "selected"
  sha_pinning_required = true
  allowed_actions_config {
    github_owned_allowed = false
    verified_allowed     = false
    patterns_allowed = [
      "1password/load-secrets-action@*",
      "actions/checkout@*",
      "actions/create-github-app-token@*",
      "actions/download-artifact@*",
      "actions/setup-node@*",
      "actions/upload-artifact@*",
      "aws-actions/configure-aws-credentials@*",
      "jdx/mise-action@*",
      "kentaro-m/auto-assign-action@*",
    ]
  }
  depends_on = [module.this]
}
