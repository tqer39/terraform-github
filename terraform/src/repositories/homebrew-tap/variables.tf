variable "github_token" {
  type        = string
  description = "GitHub token"
  sensitive   = true
}

variable "publisher_app_id" {
  type        = number
  description = "Formula を直接更新する公開専用 App の ID。Installation ID ではない。"
  default     = 5363329

  validation {
    condition     = var.publisher_app_id > 0 && floor(var.publisher_app_id) == var.publisher_app_id
    error_message = "publisher_app_id は正の整数の GitHub App ID を指定すること。"
  }
}
