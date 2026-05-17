module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "terraform-vercel"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["terraform", "vercel"]
  description         = "Configure Vercel resources with Terraform."
}
