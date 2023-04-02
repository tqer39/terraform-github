resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = github_branch.this.branch

  depends_on = [
    github_repository.this,
  ]
}
