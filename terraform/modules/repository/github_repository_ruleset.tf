resource "github_repository_ruleset" "this" {
  for_each    = var.branch_rulesets
  repository  = local.repository_name
  name        = each.key
  target      = try(each.value.target, "branch")
  enforcement = try(each.value.enforcement, "active")

  conditions {
    ref_name {
      include = try(each.value.conditions.ref_name.include, [])
      exclude = try(each.value.conditions.ref_name.exclude, [])
    }
  }

  rules {
    # Require pull requests before merging
    dynamic "pull_request" {
      for_each = try(each.value.rules.pull_request, null) != null ? [each.value.rules.pull_request] : []
      content {
        require_code_owner_review         = try(pull_request.value.require_code_owner_review, false)
        require_last_push_approval        = try(pull_request.value.require_last_push_approval, false)
        dismiss_stale_reviews_on_push     = try(pull_request.value.dismiss_stale_reviews_on_push, false)
        required_approving_review_count   = try(pull_request.value.required_approving_review_count, 1)
        required_review_thread_resolution = try(pull_request.value.required_review_thread_resolution, false)
      }
    }

    # Require status checks
    dynamic "required_status_checks" {
      for_each = try(each.value.rules.required_status_checks, null) != null && length(try(
        each.value.rules.required_status_checks.required_checks,
        each.value.rules.required_status_checks.required_check,
        []
      )) > 0 ? [each.value.rules.required_status_checks] : []
      content {
        dynamic "required_check" {
          for_each = try(
            required_status_checks.value.required_checks,
            required_status_checks.value.required_check,
            []
          )
          content {
            context        = required_check.value.context
            integration_id = try(required_check.value.integration_id, null)
          }
        }
        strict_required_status_checks_policy = try(
          required_status_checks.value.strict,
          required_status_checks.value.strict_required_status_checks_policy,
          true
        )
      }
    }

    # Branch protection rules
    deletion                = try(each.value.rules.deletion, false)
    non_fast_forward        = try(each.value.rules.non_fast_forward, false)
    required_linear_history = try(each.value.rules.required_linear_history, true)
    required_signatures     = try(each.value.rules.required_signatures, false)

    # Additional rules
    dynamic "commit_message_pattern" {
      for_each = try(each.value.rules.commit_message_pattern, null) != null ? [each.value.rules.commit_message_pattern] : []
      content {
        pattern  = commit_message_pattern.value.pattern
        operator = commit_message_pattern.value.operator
        negate   = try(commit_message_pattern.value.negate, false)
      }
    }

    dynamic "commit_author_email_pattern" {
      for_each = try(each.value.rules.commit_author_email_pattern, null) != null ? [each.value.rules.commit_author_email_pattern] : []
      content {
        pattern  = commit_author_email_pattern.value.pattern
        operator = commit_author_email_pattern.value.operator
        negate   = try(commit_author_email_pattern.value.negate, false)
      }
    }

    dynamic "branch_name_pattern" {
      for_each = try(each.value.rules.branch_name_pattern, null) != null ? [each.value.rules.branch_name_pattern] : []
      content {
        pattern  = branch_name_pattern.value.pattern
        operator = branch_name_pattern.value.operator
        negate   = try(branch_name_pattern.value.negate, false)
      }
    }
  }

  # Bypass actors configuration
  dynamic "bypass_actors" {
    for_each = concat(
      try(each.value.bypass_actors, []),
      var.enable_owner_bypass ? [{
        actor_id    = 5 # Admin role ID
        actor_type  = "RepositoryRole"
        bypass_mode = "pull_request"
      }] : []
    )
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = try(bypass_actors.value.bypass_mode, "always")
    }
  }

  depends_on = [
    github_repository.this,
    github_repository.this_from_template,
  ]
}
