module "this" {
  source         = "../../../modules/repository"
  github_token   = var.github_token
  repository     = "omnodi"
  owner          = "tqer39"
  default_branch = "main"
  visibility     = "public"

  # dev-standards.yml の standards-check はすべての PR で動くため、必須チェックに加える。
  default_main_protection_additional_required_checks = ["standards-check"]
}
