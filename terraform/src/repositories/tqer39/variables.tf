variable "github_token" {
  type        = string
  description = "GitHub token"
  sensitive   = true
}

variable "gha_app_id" {
  type        = number
  description = "3D contribution 更新に使う GHA_APP_ID。Installation ID ではなく GitHub App ID。"

  validation {
    condition     = var.gha_app_id > 0 && floor(var.gha_app_id) == var.gha_app_id
    error_message = "gha_app_id は正の整数の GitHub App ID を指定すること。"
  }
}
