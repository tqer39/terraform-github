resource "github_branch" "this" {
  for_each = { for k, branch in var.branches_to_protect : k => branch if branch != "main" }

  repository = github_repository.this.name
  branch     = each.key

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    github_repository.this,
  ]
}
