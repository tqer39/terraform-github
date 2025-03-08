resource "github_branch_protection" "this" {
  repository_id           = github_repository.this.name
  for_each                = var.branches_to_protect
  pattern                 = each.key
  enforce_admins          = try(each.value.enforce_admins, false)
  require_signed_commits  = try(each.value.require_signed_commits, false)
  allows_deletions        = try(each.value.allows_deletions, false)
  allows_force_pushes     = try(each.value.allows_force_pushes, false)
  required_linear_history = try(each.value.required_linear_history, true)

  dynamic "required_status_checks" {
    for_each = try(each.value.required_status_checks, false) ? [each.value.required_status_checks] : []
    content {
      strict   = try(each.value.status_check_up_to_date, true)
      contexts = try(each.value.status_check_contexts, [])
    }
  }

  dynamic "required_pull_request_reviews" {
    for_each = try(each.value.required_pull_request_reviews, false) ? [each.value.required_pull_request_reviews] : []
    content {
      dismiss_stale_reviews           = try(each.value.dismiss_stale_reviews, false)
      restrict_dismissals             = try(each.value.restrict_dismissals, false)
      dismissal_restrictions          = try(each.value.dismissal_restrictions, [])
      pull_request_bypassers          = try(each.value.pull_request_bypassers, [])
      require_code_owner_reviews      = try(each.value.require_code_owner_reviews, false)
      required_approving_review_count = try(each.value.required_approving_review_count, 1)
      require_last_push_approval      = try(each.value.require_last_push_approval, false)
    }
  }

  depends_on = [
    github_repository.this,
  ]
}
