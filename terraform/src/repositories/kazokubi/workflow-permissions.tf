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
