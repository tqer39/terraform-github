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

  # public リポジトリへの秘密情報の混入と、未固定アクションの実行を GitHub 側で拒否する。
  secret_scanning                 = true
  secret_scanning_push_protection = true
  sha_pinning_required            = true
}

# 公開済みの版タグの付け替えと削除を禁止する。自律保守が新しい版を公開できるよう、作成は制限しない。
resource "github_repository_ruleset" "release_tags" {
  name        = "immutable-release-tags"
  repository  = "dev-standards"
  target      = "tag"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["refs/tags/v*"]
      exclude = []
    }
  }
  rules {
    deletion = true
    update   = true
  }
  depends_on = [module.this]
}
