module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  # 既存リポジトリの改名。Terraform rootとS3 stateキーは継続し、履歴・Issue・PRを保持する。
  repository     = "kazokubi"
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
