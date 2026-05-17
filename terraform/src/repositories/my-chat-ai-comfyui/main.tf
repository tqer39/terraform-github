module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "my-chat-ai-comfyui"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["comfyui", "chat-ai"]
  description         = "Integrate chat AI features with ComfyUI"
}
