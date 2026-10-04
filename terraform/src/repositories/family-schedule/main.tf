module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository     = "family-schedule"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "private"
  description    = "Family schedules and shared tasks with Google Calendar, built on Cloudflare Workers and D1."
  topics = [
    "cloudflare-workers",
    "d1",
    "family",
    "google-calendar",
    "react",
    "task-management",
    "typescript",
  ]
}
