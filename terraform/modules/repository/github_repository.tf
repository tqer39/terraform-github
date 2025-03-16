resource "github_repository" "this" {
  name                   = var.repository
  description            = var.description
  visibility             = var.visibility
  topics                 = concat(var.topics, ["managed-by-terraform-github"])
  has_issues             = var.has_issues
  has_wiki               = var.has_wiki
  has_projects           = var.has_projects
  auto_init              = var.auto_init
  allow_auto_merge       = var.allow_auto_merge
  allow_update_branch    = var.allow_update_branch
  delete_branch_on_merge = var.delete_branch_on_merge
  vulnerability_alerts   = var.vulnerability_alerts
  archived               = var.archived

  lifecycle {
    ignore_changes = [
      auto_init,
    ]
  }
}
