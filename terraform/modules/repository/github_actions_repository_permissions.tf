resource "github_actions_repository_permissions" "this" {
  count = var.configure_actions_permissions ? 1 : 0

  repository      = github_repository.this.name
  allowed_actions = var.allowed_actions

  dynamic "allowed_actions_config" {
    for_each = var.allowed_actions == "selected" ? [1] : []
    content {
      github_owned_allowed = var.github_owned_allowed
      patterns_allowed     = var.patterns_allowed
      verified_allowed     = var.verified_allowed
    }
  }

  depends_on = [
    github_repository.this,
  ]
}
