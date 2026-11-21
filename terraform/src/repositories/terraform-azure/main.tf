module "this" {
  source         = "../../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-azure"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "public"
  topics         = ["terraform", "azure"]
  description    = "Configure Azure resources with Terraform."
}

# GitHub で作成したリポジトリを初回適用時に Terraform の state に取り込む。
import {
  to = module.this.github_repository.this[0]
  id = "terraform-azure"
}
