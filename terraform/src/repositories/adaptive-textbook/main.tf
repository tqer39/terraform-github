module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository     = "adaptive-textbook"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "private"
  description    = "Personalized technical textbooks with adaptive concept difficulty and hands-on learning history."
  topics = [
    "adaptive-learning",
    "education",
    "textbook",
  ]
  configure_actions_permissions = false
}
