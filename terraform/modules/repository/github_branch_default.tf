resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = var.branch

  depends_on = [
    github_repository.this,
  ]
}
