module "this" {
  source         = "../../../modules/repository"
  github_token   = var.github_token
  repository     = "orca-agent-map"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "public"
  description    = "Live agent-to-agent request map panel for Orca"

  # dev-standards.yml の standards-check はすべての PR で動くため、必須チェックに加える。
  default_main_protection_additional_required_checks = ["standards-check"]
}

# GitHub で作成したリポジトリを初回適用時に Terraform の state に取り込む。
import {
  to = module.this.github_repository.this[0]
  id = "orca-agent-map"
}
