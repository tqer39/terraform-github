# コマンドリファレンス

terraform-github リポジトリ操作の詳細コマンドリファレンス。

## 初期セットアップ

```bash
make bootstrap       # 必要なツールを一括インストール
just setup           # 開発環境のセットアップ
just check-tools     # インストール状態の確認
```

## Terraform 操作

| コマンド | 説明 |
| ------- | ---- |
| `just fmt` | 全 Terraform ファイルをフォーマット |
| `just init` | Terraform の初期化 |
| `just validate` | 設定の検証 |
| `just plan` | 変更の計画 |
| `just apply` | 変更の適用（ローカル実行は注意） |

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
| `just lint` | 全 pre-commit フックを実行 |
| `just lint-hook <hook>` | 特定フックを実行（terraform_fmt, terraform_validate, terraform_tflint, yamllint, markdownlint） |
| `just fix` | よくある問題を自動修正 |
| `just fmt-staged` | ステージ済みファイルをフォーマット |

## Git Worktree

```bash
just worktree-setup                                    # インタラクティブセットアップ
git worktree add ../terraform-github-<branch> -b <branch>  # 手動追加
git worktree list                                      # 一覧表示
git worktree remove ../terraform-github-<branch>      # 削除
```

## メンテナンス

| コマンド | 説明 |
| ------- | ---- |
| `just clean` | Terraform 一時ファイルを削除 |
| `just version` | バージョン表示 |
| `just status` | mise 管理ツールのバージョン表示 |
| `just install` | .tool-versions からツールをインストール |
| `just update` | mise 管理ツールを更新 |
| `just update-brew` | brew パッケージを更新 |

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
