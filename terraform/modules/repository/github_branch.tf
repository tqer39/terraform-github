resource "github_branch" "this" {
  for_each = { for k, v in var.branches_to_protect : k => v if k != "main" }

  repository = github_repository.this.name
  branch     = each.key

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    github_repository.this,
  ]
}
