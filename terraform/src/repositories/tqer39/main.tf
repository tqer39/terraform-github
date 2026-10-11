module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "tqer39"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["profile"]
  description         = "personal information repository"

  # 3D contribution 更新用の Actions App だけに直接 push を許可する。
  default_main_protection_bypass_app_ids = [var.gha_app_id]
}
