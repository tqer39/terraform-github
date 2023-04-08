resource "github_actions_repository_permissions" "this" {
  repository      = github_repository.this.name
  allowed_actions = var.allowed_actions

  allowed_actions_config {
    github_owned_allowed = var.github_owned_allowed
    patterns_allowed     = var.patterns_allowed
    verified_allowed     = var.verified_allowed
  }

  depends_on = [
    github_repository.this,
  ]
}
