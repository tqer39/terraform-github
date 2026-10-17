module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  # Terraform root の名称を kazokubi に統一。既存 S3 state とリソースアドレスを引き継ぐ。
  repository     = "kazokubi"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "private"

  # 管理者にも PR と必須 CI を要求し、Action の許可設定は専用 resource で管理する。
  default_main_protection_owner_bypass = false
  configure_actions_permissions        = false
  description                          = "Family schedules and shared tasks with Google Calendar, built on Cloudflare Workers and D1."
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
