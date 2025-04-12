module "anime_tweet_bot" {
  source         = "../../modules/repository"
  github_token   = var.github_token
  repository     = "anime-tweet-bot"
  default_branch = "main"
  topics         = ["x", "bot"]
  description    = "A bot for tweeting about anime."
  branches_to_protect = {
    "main" = {
      required_status_checks        = true
      required_pull_request_reviews = true
    }
  }
}
