# コマンドリファレンス

terraform-github リポジトリ操作の詳細コマンドリファレンス。

## 初期セットアップ

```bash
./scripts/bootstrap.sh   # mise と Git をインストール (Homebrew + Brewfile)
mise bootstrap --only tools,task # ツール、固定依存、Git フックをセットアップ
mise run check-tools     # インストール状態の確認
```

## Terraform 操作

| コマンド | 説明 |
| ------- | ---- |
| `mise run tf:fmt` | 全 Terraform ファイルをフォーマット |
| `mise run tf:init` | Terraform の初期化 |
| `mise run tf:validate` | 設定の検証 |
| `mise run tf:plan` | 変更の計画 |
| `mise run tf:apply` | 変更の適用（ローカル実行は注意） |

既定の root は `terraform-github`。`mise run tf:plan -- <repo-name>` のように対象を指定できる。
`TERRAFORM_DIR` で既定 root を変更できる。対象 root に対応する AWS と GitHub 認証が必要。

保存 plan を確認して適用する手順:

```bash
AWS_PROFILE=portfolio mise run tf:init -- terraform-github -input=false
mise run tf:validate -- terraform-github
AWS_PROFILE=portfolio mise run tf:plan -- terraform-github -out=tfplan
mise exec -- terraform -chdir=terraform/src/repositories/terraform-github show tfplan
AWS_PROFILE=portfolio mise run tf:apply -- terraform-github tfplan
```

手動 Actions は `repository` で1件を選択し、全件は `all` を指定する。
`apply=false` で plan を確認し、適用時は true を指定する。
PR と push は差分から対象を選び、共通 module / Terraform Action 変更は全 root の plan のみを処理する。
共通変更の適用は plan 確認後の手動実行で明示する。

### 既存リポジトリのインポート

```bash
cd terraform/src/repositories/<repo-name>
terraform import module.this.github_repository.this <repo_name>
terraform import module.this.github_branch_default.this <repo_name>
terraform import module.this.github_actions_repository_permissions.this <repo_name>
terraform import module.this.github_repository_ruleset.this[\"<ruleset_name>\"] <repo_name>:<ruleset_id>
```

### GitHub Actions 経由のインポート

1. Actions タブ → "Terraform Import" ワークフローを開く
2. "Run workflow" をクリックし、パラメータを入力:
   - `module`: モジュール名（例: `this`）
   - `repo`: GitHub リポジトリ名
3. ワークフローがインポート: リポジトリ設定、デフォルトブランチ、Actions 権限、ブランチ保護

## コード品質

| コマンド | 説明 |
| ------- | ---- |
| `mise run lint` / `mise run dev:lint` | 回帰テストと全 pre-commit フックを実行 |
| `mise run dev:test` | 実行対象、秘密検出、モジュールの回帰テスト |
| `mise run dev:lint-hook -- <hook>` | 特定フックを実行（terraform-fmt, oxfmt, yamllint, markdownlint） |
| `mise run rules:sync` | LLM 向けの共通ルール参照を生成 |
| `mise run rules:check` | 生成結果の更新漏れを検出 |
| `mise run dev:fix` | よくある問題を自動修正 |
| `mise run dev:fmt-staged` | ステージ済みファイルをフォーマット |
| `scripts/lint/check-terraform-lock.sh` | `terraform/src/repositories/<repo>/` 配下の `.terraform.lock.hcl` 欠落を検出（lefthook の `check-terraform-lock` フックから自動実行） |

## Git worktree

```bash
mise run wt:setup                                       # インタラクティブセットアップ
git worktree add ../terraform-github-<branch> -b <branch>  # 手動追加
git worktree list                                       # 一覧表示
git worktree remove ../terraform-github-<branch>       # 削除
```

## メンテナンス

| コマンド | 説明 |
| ------- | ---- |
| `mise run tf:clean` | Terraform 一時ファイルを削除 |
| `mise run version` | バージョン表示 |
| `mise run status` | mise 管理ツールのバージョン表示 |
| `mise run install` | mise.toml からツールをインストール |
| `mise run update` | mise 管理ツールを更新 |
| `mise run update-brew` | brew パッケージを更新 |

## リポジトリ削除手順

1. AWS 認証情報を使って Terraform state から削除:

```bash
aws-vault exec portfolio -- terraform -chdir=./terraform/src/repositories/<repo-name> state rm module.this
```

※ `portfolio` は `~/.aws/config` で設定された SSO ロールの AWS プロファイル名。

1. ソースディレクトリを削除: `terraform/src/repositories/<repo-name>/`

2. GitHub リポジトリを削除:

```bash
gh repo delete <owner>/<repo-name> --confirm
```

## リポジトリシークレット

```bash
./scripts/set-common-github-secrets.sh <github_owner>
```
