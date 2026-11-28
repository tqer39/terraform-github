module "this" {
  source         = "../../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-gcp"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "public"
  topics         = ["terraform", "gcp"]
  description    = "Configure Google Cloud resources with Terraform."

  # dev-standards.yml の standards-check はすべての PR で動くため、必須チェックに加える。
  default_main_protection_additional_required_checks = ["standards-check"]
}

# GitHub で作成したリポジトリを初回適用時に Terraform の state に取り込む。
import {
  to = module.this.github_repository.this[0]
  id = "terraform-gcp"
}
