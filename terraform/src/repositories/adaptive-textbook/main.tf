# Keep this root and its backend key stable to rename the existing repository in place.
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
}
