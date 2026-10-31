module "this" {
  source                      = "../../../modules/repository"
  github_token                = var.github_token
  repository                  = "dev-standards"
  owner                       = "tqer39"
  default_branch              = "main"
  visibility                  = "public"
  description                 = "個人開発リポジトリの共通ルールを版管理し、計画に基づいて適用・再適用する CLI"
  has_wiki                    = true
  has_projects                = true
  allow_auto_merge            = false
  allow_update_branch         = false
  delete_branch_on_merge      = false
  vulnerability_alerts        = false
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
}
