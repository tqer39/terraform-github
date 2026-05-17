module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "terraform-aws"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["terraform", "aws"]
  description         = "Configure AWS resources with Terraform."
}
