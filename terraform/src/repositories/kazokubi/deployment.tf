# 非公開・非Enterpriseではrequired reviewersが使えないため、承認はmainの
# workflow_dispatchで運用者を検証する。EnvironmentはSecretsと実行元を分離する。
resource "github_repository_environment" "release" {
  for_each    = toset(["dev", "production"])
  repository  = "kazokubi"
  environment = each.key
  # private Pro ではバイパス禁止を設定できず、API は true を返す。
  # ignore_changes で隠さず実値を管理し、承認は main の workflow 側で強制する。
  # 公開範囲・契約変更時は Required reviewers と併せて再評価する。
  can_admins_bypass   = true
  prevent_self_review = false
  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
  depends_on = [module.this]
}
resource "github_repository_environment_deployment_policy" "release" {
  for_each       = github_repository_environment.release
  repository     = "kazokubi"
  environment    = each.value.environment
  branch_pattern = "main"
}
resource "github_repository_ruleset" "release_tags" {
  name        = "immutable-release-tags"
  repository  = "kazokubi"
  target      = "tag"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["refs/tags/v*"]
      exclude = []
    }
  }
  rules {
    deletion = true
    update   = true
  }
  depends_on = [module.this]
}
variable "discord_webhook_url" {
  description = "Discord Terraformのsensitive出力。承認前の通知にも必要なためrepository Secretへ保存。"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^https://discord\\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+$", var.discord_webhook_url))
    error_message = "DiscordのWebhook URLを環境変数経由で指定してください。"
  }
}
resource "github_actions_secret" "discord" {
  repository  = "kazokubi"
  secret_name = "DISCORD_WEBHOOK_URL"
  value       = var.discord_webhook_url
  depends_on  = [module.this]
  lifecycle {
    prevent_destroy = true
  }
}
# 実値はTF_VAR_release_secretsから渡す。未指定では作成・上書きしない。
variable "release_secrets" {
  description = "Dev・本番ごとのDB/Cloudflare資格情報と独立したDBバックアップ暗号鍵。"
  type        = map(map(string))
  sensitive   = true
  default     = {}
  validation {
    condition = alltrue([for environment, secrets in var.release_secrets :
      contains(["dev", "production"], environment) &&
      alltrue([for name, value in secrets : contains(["TURSO_AUTH_TOKEN", "CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID", "DB_BACKUP_KEY"], name) && length(value) > 0])
    ])
    error_message = "公開用Secretsはdev/productionと許可されたキーを指定してください。"
  }
}
locals {
  release_secret_keys = flatten([for environment, secrets in nonsensitive(var.release_secrets) : [for name in keys(secrets) : "${environment}/${name}"]])
}
resource "github_actions_environment_secret" "release" {
  for_each    = toset(local.release_secret_keys)
  repository  = "kazokubi"
  environment = github_repository_environment.release[split("/", each.value)[0]].environment
  secret_name = split("/", each.value)[1]
  value       = var.release_secrets[split("/", each.value)[0]][split("/", each.value)[1]]
  lifecycle {
    prevent_destroy = true
  }
}
