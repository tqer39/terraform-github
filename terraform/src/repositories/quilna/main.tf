# Keep the legacy backend key so the renamed root uses the existing repository state.
module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository     = "quilna"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "public"
  description    = "Quilna: select information, think, and compile your own textbooks."
  homepage_url   = "https://quilna.page"
  topics = [
    "adaptive-learning",
    "education",
    "textbook",
  ]
  configure_actions_permissions = false

  # dev-standards.yml の standards-check はすべての PR で動くため、必須チェックに加える。
  default_main_protection_additional_required_checks = ["standards-check"]
}
