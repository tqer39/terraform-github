module "this" {
  source         = "../../../modules/repository"
  github_token   = var.github_token
  repository     = "infra-canvas"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "public"
}
