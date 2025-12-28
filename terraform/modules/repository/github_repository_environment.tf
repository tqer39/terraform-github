locals {
  environment_reviewer_usernames = distinct(flatten([
    for env_name, env_config in var.environments :
    try(env_config.reviewers.users, [])
  ]))
}

data "github_user" "environment_reviewers" {
  for_each = toset(local.environment_reviewer_usernames)
  username = each.value
}

resource "github_repository_environment" "this" {
  for_each = var.environments

  repository          = local.repository_name
  environment         = each.key
  prevent_self_review = try(each.value.prevent_self_review, false)
  wait_timer          = try(each.value.wait_timer, null)
  can_admins_bypass   = try(each.value.can_admins_bypass, true)

  dynamic "reviewers" {
    for_each = try(each.value.reviewers, null) != null ? [each.value.reviewers] : []
    content {
      users = try(reviewers.value.users, null) != null ? [
        for username in reviewers.value.users :
        data.github_user.environment_reviewers[username].id
      ] : null
      teams = try(reviewers.value.teams, null)
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = try(each.value.deployment_branch_policy, null) != null ? [each.value.deployment_branch_policy] : []
    content {
      protected_branches     = try(deployment_branch_policy.value.protected_branches, false)
      custom_branch_policies = try(deployment_branch_policy.value.custom_branch_policies, false)
    }
  }

  depends_on = [
    github_repository.this,
    github_repository.this_from_template,
  ]
}
