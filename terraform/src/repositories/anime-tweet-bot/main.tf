module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "anime-tweet-bot"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["x", "bot"]
  description         = "A bot for tweeting about anime."
}
