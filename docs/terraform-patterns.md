# Terraform パターン

リポジトリ設定の HCL パターン。実例は `terraform/src/repositories/` 配下の既存ディレクトリを参照。

## モダンアプローチ（Repository Rulesets）- 推奨

```hcl
module "my_new_repo" {
  source = "../../../modules/repository"

  github_token    = var.github_token
  repository      = "my-new-repo"
  owner           = "AIPairStudio"  # 省略可: Organization 名
  description     = "Repository description"
  default_branch  = "main"
  visibility      = "public"  # or "private"
  topics          = ["terraform", "automation"]

  branch_rulesets = {
    "main" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]
          exclude = []
        }
      }
      rules = {
        pull_request = {
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = true
          required_approving_review_count   = 1
          required_review_thread_resolution = true
        }
      }
    }
  }
}
```

## レガシーアプローチ（Branch Protection）

```hcl
module "my_legacy_repo" {
  source = "../../../modules/repository"

  github_token    = var.github_token
  repository      = "my-legacy-repo"
  description     = "Repository description"
  default_branch  = "main"
  topics          = ["terraform", "automation"]

  branches_to_protect = {
    main = {
      required_status_checks         = true
      required_pull_request_reviews  = true
      dismiss_stale_reviews          = true
      require_code_owner_reviews     = true
      required_approving_review_count = 1
    }
  }
}
```

## 主要モジュールパラメータ

| パラメータ | 必須 | 説明 |
| --------- | ---- | ---- |
| `repository` | Yes | リポジトリ名 |
| `owner` | No | Organization 名（省略時は個人アカウント） |
| `description` | No | リポジトリの説明 |
| `visibility` | No | `public` または `private` |
| `default_branch` | No | デフォルトブランチ名（通常 `main`） |
| `topics` | No | リポジトリのトピック/タグ一覧 |
| `branch_rulesets` | No | モダンなルールベース保護（推奨） |
| `branches_to_protect` | No | レガシーブランチ保護 |
| `has_wiki`, `has_issues`, `has_projects` | No | 機能トグル |
| `allow_merge_commit`, `allow_squash_merge`, `allow_rebase_merge` | No | マージ戦略 |
