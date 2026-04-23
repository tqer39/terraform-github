module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "homebrew-tap"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "Homebrew tap for tqer39 tools (ccw-cli など)"
  visibility          = "public"
  topics = [
    "homebrew",
    "homebrew-tap",
    "formula",
  ]
}
