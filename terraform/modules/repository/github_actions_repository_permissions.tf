resource "github_actions_repository_permissions" "this" {
  repository      = github_repository.this.name
  allowed_actions = try(var.allowed_actions, "selected")

  allowed_actions_config {
    github_owned_allowed = try(var.github_owned_allowed, true)
    patterns_allowed = try(var.patterns_allowed, [
      "actions/cache@*",
      "actions/checkout@*",
    ])
    verified_allowed = try(var.verified_allowed, true)
  }

  depends_on = [
    github_repository.this,
  ]
}
