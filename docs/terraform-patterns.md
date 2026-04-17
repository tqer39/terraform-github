# Terraform パターン

リポジトリ設定の HCL パターン。実例は `terraform/src/repositories/` 配下の既存ディレクトリを参照。

## デフォルト main ブランチ保護（opt-out 方式）

モジュールを呼ぶだけで `main` の標準保護が自動適用される（opt-out 方式）。

標準保護の内容:

| ルール | 値 |
| --- | --- |
| force push 禁止 | `non_fast_forward = true` |
| ブランチ削除禁止 | `deletion = true` |
| linear history 必須 | `required_linear_history = true` |
| PR 必須 | あり |
| 承認数 | `0`（1 人開発向け） |
| stale review 自動却下 | `dismiss_stale_reviews_on_push = true` |
| スレッド解決必須 | `required_review_thread_resolution = true` |
| 必須ステータスチェック | `workflow-result` |
| 所有者 bypass | `bypass_mode = "pull_request"`（デフォルト有効） |

### 最小構成（標準保護のみ）

```hcl
module "my_new_repo" {
  source = "../../../modules/repository"

  github_token   = var.github_token
  repository     = "my-new-repo"
  description    = "Repository description"
  default_branch = "main"
  visibility     = "public"
  topics         = ["terraform", "automation"]
  # branch_rulesets / disable_default_main_protection は省略
  # → main の標準保護が自動で作成される
}
```

### 標準保護を無効にするケース

archived リポジトリや保護が不要なリポジトリは `disable_default_main_protection = true` を明示する。

```hcl
module "archived_repo" {
  source = "../../../modules/repository"

  github_token   = var.github_token
  repository     = "my-archived-repo"
  description    = "Archived repository"
  visibility     = "private"
  archived       = true

  # archived / 保護不要な repo は明示的に無効化する
  disable_default_main_protection = true
}
```

## モダンアプローチ（Repository Rulesets）- 追加・例外用途

`branch_rulesets` は標準保護に加えて**追加の ruleset が必要なとき**、または **`main` 以外のブランチに保護をかけるとき**に使う。`branch_rulesets` に `"main"` キーを追加すると標準保護と名前が衝突するため、`disable_default_main_protection = true` を併用すること（モジュールの precondition で検出される）。

```hcl
module "my_new_repo" {
  source = "../../../modules/repository"

  github_token   = var.github_token
  repository     = "my-new-repo"
  description    = "Repository description"
  default_branch = "main"
  visibility     = "public"
  topics         = ["terraform", "automation"]

  # 標準保護に加えて release ブランチにも保護をかける例
  branch_rulesets = {
    "release" = {
      enforcement = "active"
      conditions = {
        ref_name = {
          include = ["refs/heads/release/**"]
          exclude = []
        }
      }
      rules = {
        pull_request = {
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = false
          required_approving_review_count   = 0
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
| `disable_default_main_protection` | No | `true` にすると標準 main 保護を無効化（デフォルト: `false`） |
| `default_main_protection_owner_bypass` | No | 標準 main 保護で所有者 bypass を許可するか（デフォルト: `true`） |
| `branch_rulesets` | No | 追加 ruleset（`main` 以外や特殊な上書きに使用） |
| `branches_to_protect` | No | レガシーブランチ保護（非推奨） |
| `has_wiki`, `has_issues`, `has_projects` | No | 機能トグル |
| `allow_merge_commit`, `allow_squash_merge`, `allow_rebase_merge` | No | マージ戦略 |
