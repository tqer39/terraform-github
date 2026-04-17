# 設計: 個人開発向け軽量 `main` ブランチ保護の標準化

- 作成日: 2026-04-18
- 作業ブランチ: `feat/main-branch-protection-ruleset`
- 関連 worktree: `../terraform-github-worktrees/main-branch-protection-ruleset`

## 背景と目的

`terraform-github` 管理下の 31 リポジトリは、すべて個人開発（`tqer39` 単独）。現状 28 リポジトリに GitHub Rulesets が設定されているが、以下のギャップがある。

1. `required_approving_review_count = 1` が全 28 リポジトリで設定されているが、1 人開発では PR 作成者自身が approve できないため、実質マージ不能になる瞬間がありうる。
2. `deletion` / `non_fast_forward` / `required_linear_history` はモジュール側のデフォルトに依存しており、個別リポジトリに明示されていない。
3. `required_status_checks` の有無・context 名（`prek` / `workflow-result` / `pre-commit` 混在）が統一されていない。最近の commit (`de54b6f`) で `workflow-result` に集約する方針が出ている。
4. `enable_owner_bypass = true` が全 28 リポジトリで重複記述されている。
5. `docs/terraform-patterns.md` の推奨例と実装がズレている。

これらを **モジュール側のデフォルトを「1 人向け標準」に寄せる** ことで解消し、各リポジトリからは重複記述を消す。

### 標準ルールの定義（ユーザー合意済み）

| ルール | 値 | 意図 |
| --- | --- | --- |
| `deletion` | `true` | `main` の削除禁止 |
| `non_fast_forward` | `true` | force push 禁止 |
| `required_linear_history` | `true` | squash / rebase マージのみ許容 |
| PR 必須 | あり | 直 push を防ぐ |
| `required_approving_review_count` | `0` | 1 人開発で approve の儀式を排除 |
| `dismiss_stale_reviews_on_push` | `true` | approve の持ち越しを防ぐ |
| `required_review_thread_resolution` | `true` | レビューコメント未解決のマージを防ぐ |
| `required_status_checks` | `["workflow-result"]` | CI が main のゲートになる |
| `enable_owner_bypass`（所有者） | `true`（デフォルト） | 緊急時の脱出弁 |

## アーキテクチャ

### 新リソース: `github_repository_ruleset.default_main_protection`

`terraform/modules/repository/github_repository_ruleset.tf` に追加。既存の `github_repository_ruleset.this`（`for_each = var.branch_rulesets`）はそのまま残し、共存させる。

```hcl
resource "github_repository_ruleset" "default_main_protection" {
  count       = var.disable_default_main_protection ? 0 : 1
  name        = "main"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      required_review_thread_resolution = true
    }

    required_status_checks {
      strict_required_status_checks_policy = false
      required_check {
        context = "workflow-result"
      }
    }
  }

  dynamic "bypass_actors" {
    for_each = var.default_main_protection_owner_bypass ? [1] : []
    content {
      actor_id    = 5 # RepositoryRole: Admin
      actor_type  = "RepositoryRole"
      bypass_mode = "always"
    }
  }
}
```

実装時の検証ステップ: `actor_id = 5` は GitHub Provider の仕様上 Admin role を指すが、実装着手時に既存 28 repo の `github_repository_ruleset.this["main"].bypass_actors[0].actor_id` の値と一致することを確認する（現状の `enable_owner_bypass = true` が同じ actor_id を生成している前提）。

### 不変条件

`disable_default_main_protection = false`（デフォルト）かつ `var.branch_rulesets` に `"main"` キーのエントリがある場合、GitHub 側で ruleset 名が重複し API エラーになる。`lifecycle.precondition` または `check` ブロックで弾く。

```hcl
lifecycle {
  precondition {
    condition     = var.disable_default_main_protection || !contains(keys(var.branch_rulesets), "main")
    error_message = "default_main_protection と branch_rulesets[\"main\"] は共存できない。disable_default_main_protection = true にするか branch_rulesets から main を外すこと。"
  }
}
```

## 変数定義（追加）

`terraform/modules/repository/variables.tf`:

```hcl
variable "disable_default_main_protection" {
  description = "true にすると、標準 main ブランチ保護 ruleset を無効化する。obsidian-vault など保護不要な repo 用。"
  type        = bool
  default     = false
}

variable "default_main_protection_owner_bypass" {
  description = "標準 main ブランチ保護で、リポジトリ所有者による bypass を許可するか。"
  type        = bool
  default     = true
}
```

### 意図的にハードコード（var にしない）

シンプル性優先で以下はモジュール内にハードコード:

- `required_status_checks.required_check.context = "workflow-result"`
- `required_approving_review_count = 0`
- `deletion = true` / `non_fast_forward = true` / `required_linear_history = true`

必要が出たら将来 var 化する。YAGNI。

## 既存 28 リポジトリの移行（state mv）

### 対象

`terraform/src/repositories/` 配下で `branch_rulesets` に `"main"` エントリを持つ 28 リポジトリ。

### 1 リポジトリあたりの手順

1. `terraform/src/repositories/<repo>/main.tf` から `branch_rulesets` の `"main"` エントリを削除（他の ruleset があれば残す）。`enable_owner_bypass` の記述も削除。
2. 次のコマンドで state 上のリソース名を付け替え:

   ```bash
   terraform state mv \
     'module.this.github_repository_ruleset.this["main"]' \
     'module.this.github_repository_ruleset.default_main_protection[0]'
   ```

3. `terraform plan` で差分確認:
   - **理想**: `approvals: 1 → 0` の in-place update のみ
   - **許容**: `deletion` / `non_fast_forward` / `required_linear_history` の明示化差分、`required_status_checks` に `workflow-result` がない repo は context 追加
   - **中止シグナル**: `destroy + create` が出たら state mv 失敗として調査

### 自動化

`scripts/migrate-default-main-protection.sh`（新規追加）で 28 repo の state mv を一括実行。初回は `--dry-run` モードで plan のみ表示し、目視確認後に本番実行。

### PR 段階展開

| PR | 内容 | apply 後確認 |
| --- | --- | --- |
| PR1 | モジュール変更（新 resource + var 2 つ + precondition） + archived 3 件のクリーンアップ（`local-workspace-provisioning`, `obsidian-vault-old`, `setup-develop-environments` の `disable_default_main_protection = true` 追加、必要なら `visibility = "private"` 変更） + `terraform-github` 自身の移行 | GitHub の Rulesets 画面で `terraform-github` の `main` ruleset 確認。archived 3 件は plan/apply が通ることのみ確認 |
| PR2 | 影響小の 3-5 repo（`tqer39`, `time-capsule`, `boilerplate-base`, `boilerplate-saas`, `obsidian-vault`）を移行。`obsidian-vault` は `disable_default_main_protection = true` を設定 | plan 差分が期待通りの repo のみ |
| PR3+ | 残り 22 repo を 5-10 件ずつ移行 | 各 PR で plan を目視確認 |

`obsidian-vault` は archived ではないが保護不要方針なので PR2 に含める。

## 例外リポジトリの扱い

### `disable_default_main_protection = true` を明示するリポジトリ

| repo | 現状 | 対応 |
| --- | --- | --- |
| `obsidian-vault` | `branch_rulesets = {}`、private | `disable_default_main_protection = true` を追加 |
| `obsidian-vault-old` | `branch_rulesets = {}`, archived | `disable_default_main_protection = true` を追加 |
| `setup-develop-environments` | `branch_rulesets` キーなし, archived | `disable_default_main_protection = true` を追加 |
| `local-workspace-provisioning` | ruleset 設定あり, archived | `branch_rulesets` の `main` エントリを削除 + `disable_default_main_protection = true` 追加。archived なので state mv せず既存 ruleset は destroy させる（archived repo には誰も push しない前提） |

### archived リポジトリの visibility を `private` に変更

ユーザー指示により、archived 3 件の visibility を `"private"` に変更する。

対象: `local-workspace-provisioning`, `obsidian-vault-old`, `setup-develop-environments`

手順:

1. 各 `terraform/src/repositories/<repo>/main.tf` を読み、現状 visibility を確認。
2. `public` なら `visibility = "private"` に変更。
3. `disable_default_main_protection = true` と **同じ PR** にまとめる。
4. `terraform plan` で `visibility: "public" -> "private"` の差分が出ていることを確認してから apply。

注意: public → private 化すると、star / fork / watch 数はリセットされ、公開 URL への外部リンクは 404 化する。archived かつ実質未使用ならリスク小だが、apply 前に plan を目視確認する。

## docs 更新

### `docs/terraform-patterns.md`

- 冒頭に「モジュールを呼ぶだけで `main` の標準保護が自動適用される（opt-out 方式）」を明記。
- `branch_rulesets` は例外用途（追加 ruleset や上書き）として説明を残す。
- `disable_default_main_protection = true` を書くケースの例を追加。
- 既存の実装とズレていた例（`require_code_owner_review` など）を実装に合わせて修正。

### `docs/coding-standards.md`

- 「新規 repo 追加時に標準 `main` 保護が自動適用される」項目を追加。

### `CLAUDE.md`（任意）

- 必須ルール節に「新規 repo 追加時に `disable_default_main_protection` を書かなければ、標準保護（force push 禁止 / 削除禁止 / PR 必須 / linear history / workflow-result 必須 / 承認 0）が自動適用される」を 1 行追加。

## 検証

### モジュール変更直後（まだ state mv 前）

```bash
just fmt
just validate
just plan
```

- `just plan` の差分が「モジュール内に新 resource が 1 個増える」だけで、既存 `github_repository_ruleset.this["main"]` がまだ消えていない状態であること。
- 不変条件（precondition）で全 28 repo が失敗するはず → state mv 段階で解消。

### 1 repo 試行後（`terraform-github` 自身）

- `terraform plan` で `in-place update`（主に `approvals: 1 → 0`）のみ。`destroy + create` は出ないこと。
- apply 後、GitHub の `Settings → Rules → Rulesets` 画面で `main` ruleset が存在し、approvals=0 / linear history=on / workflow-result required になっていること。

### 残り repo の一括移行

- `just plan` で全 repo の差分を一度に確認。
- 差分が予想外のリポジトリだけ個別に調査。

### ロールバック計画

- 問題発生時は `git revert` + `terraform state mv` を逆方向に実行。
- terraform state バックアップは既存の state バケットのバージョニングに依存。

## 本設計のスコープ外

- 新規 repo 追加時のテンプレート更新（必要ならフォローアップで）。
- `main` 以外のブランチ保護（release ブランチ等）— 従来通り `branch_rulesets` で対応。
- GitHub Actions ワークフロー自体の変更（`workflow-result` の有無は別件）。

## 重要ファイル（実装で触るパス）

- `terraform/modules/repository/github_repository_ruleset.tf`（新 resource 追加）
- `terraform/modules/repository/variables.tf`（var 2 つ追加）
- `terraform/src/repositories/<repo>/main.tf`（31 repo 全て、内容は repo により差分あり）
- `scripts/migrate-default-main-protection.sh`（新規追加、任意）
- `docs/terraform-patterns.md`
- `docs/coding-standards.md`
- `CLAUDE.md`（任意）
