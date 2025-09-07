resource "github_repository" "this" {
  count                  = var.template_repository == null ? 1 : 0
  name                   = var.repository
  description            = var.description
  homepage_url           = var.homepage_url
  visibility             = var.visibility
  topics                 = var.topics
  has_issues             = var.has_issues
  has_wiki               = var.has_wiki
  has_projects           = var.has_projects
  auto_init              = var.auto_init
  allow_auto_merge       = var.allow_auto_merge
  allow_update_branch    = var.allow_update_branch
  delete_branch_on_merge = var.delete_branch_on_merge
  vulnerability_alerts   = var.vulnerability_alerts
  archived               = var.archived
  is_template            = var.is_template

  lifecycle {
    ignore_changes = [
      auto_init,
    ]
  }
}

resource "github_repository" "this_from_template" {
  count                  = var.template_repository != null ? 1 : 0
  name                   = var.repository
  description            = var.description
  homepage_url           = var.homepage_url
  visibility             = var.visibility
  topics                 = var.topics
  has_issues             = var.has_issues
  has_wiki               = var.has_wiki
  has_projects           = var.has_projects
  allow_auto_merge       = var.allow_auto_merge
  allow_update_branch    = var.allow_update_branch
  delete_branch_on_merge = var.delete_branch_on_merge
  vulnerability_alerts   = var.vulnerability_alerts
  archived               = var.archived
  is_template            = var.is_template

  template {
    owner                = coalesce(var.template_owner, var.owner)
    repository           = var.template_repository
    include_all_branches = var.template_include_all_branches
  }
}

locals {
  repository_name = coalescelist(
    github_repository.this[*].name,
    github_repository.this_from_template[*].name,
  )[0]
}
