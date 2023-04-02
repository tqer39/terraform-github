resource "github_branch" "this" {
  repository = var.repository
  branch     = var.branch
}
