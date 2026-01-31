resource "github_branch_default" "this" {
  repository = local.repository_name
  branch     = var.default_branch

  depends_on = [
    github_repository.this,
    github_repository.this_from_template,
    github_repository.this_from_fork,
  ]
}
