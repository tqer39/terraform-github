module "this" {
  archived                        = true
  actions_enabled                 = false
  disable_default_main_protection = true

  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "tts-partner"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "private"
  topics              = ["tts"]
  description         = "TTS Partner repository"
}
