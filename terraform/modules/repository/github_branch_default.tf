resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = var.default_branch

  depends_on = [
    github_repository.this,
  ]
}
