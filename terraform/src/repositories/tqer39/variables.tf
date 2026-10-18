variable "github_token" {
  type        = string
  description = "GitHub token"
  sensitive   = true
}

variable "maintenance_app_id" {
  type        = number
  description = "プロフィール更新に使う保守専用 App の ID。Installation ID ではない。"
  default     = 5363311

  validation {
    condition     = var.maintenance_app_id > 0 && floor(var.maintenance_app_id) == var.maintenance_app_id
    error_message = "maintenance_app_id は正の整数の GitHub App ID を指定すること。"
  }
}
