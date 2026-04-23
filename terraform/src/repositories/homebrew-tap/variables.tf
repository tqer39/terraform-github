variable "github_token" {
  type        = string
  description = "GitHub token"
  sensitive   = true
}

variable "gha_app_id" {
  type        = string
  description = "goreleaser が Formula/*.rb を push するための GitHub App の numeric App ID (ruleset bypass actor 用)"
}
