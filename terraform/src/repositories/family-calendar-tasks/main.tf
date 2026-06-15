module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "family-calendar-tasks"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "private"
  description         = "Family task management app with bidirectional Google Calendar sync."
  topics = [
    "calendar",
    "family",
    "google-calendar",
    "sync",
    "task-management",
  ]
}
