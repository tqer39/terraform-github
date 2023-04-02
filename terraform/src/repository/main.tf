module "tqer39" {
  source = "../../modules/repository"

  GITHUB_TOKEN = var.GITHUB_TOKEN
  branch       = "main"
  repository   = "tqer39"
}
