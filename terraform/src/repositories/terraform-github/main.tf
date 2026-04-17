module "this" {
  source         = "../../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-github"
  owner          = "tqer39"
  default_branch = "main"
  topics         = ["terraform", "github"]
  description    = "Configure GitHub resources with Terraform."
}
