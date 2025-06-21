provider "github" {
  owner = var.owner != null ? var.owner : "tqer39"
  token = var.github_token
}
