# CLAUDE.md

このリポジトリで作業する際のClaude Codeへのガイダンス。

## 概要

Terraformモジュラーアーキテクチャを使用してGitHubリポジトリを管理するIaCプロジェクト。GitHub Actionsによる自動化。

## 主要パス

| パス | 目的 |
| ---- | ---- |
| `terraform/modules/repository/` | 再利用可能なTerraformモジュール（リポジトリ、ブランチ保護、ルールセット、アクション権限） |
| `terraform/src/repository/` | リポジトリ固有の設定（リポジトリごとに1つの`.tf`ファイル） |
| `.github/workflows/` | CI/CD: `terraform-github.yml` (plan/apply), `terraform-import.yml`, `prek.yml` |
| `.github/actions/` | 再利用可能なアクション: setup-terraform, terraform-validate, terraform-plan, terraform-apply |

## クイックコマンド

| タスク | コマンド |
| ------ | -------- |
| セットアップ | `make bootstrap && just setup` |
| フォーマット | `just fmt` |
| 検証 | `just validate` |
| プラン | `just plan` |
| リント | `just lint` |
| クリーン | `just clean` |

詳細コマンド（インポート、worktree、メンテナンス、削除）: `.claude/docs/commands-reference.md` 参照

## リポジトリの追加

1. `terraform/src/repository/<repo-name>.tf` を作成
2. `../../modules/repository` からモジュールを使用（必須パラメータを指定）
3. `just validate && just plan` を実行
4. レビュー用にPRを作成

HCLパターン（モダンルールセット vs レガシーブランチ保護）: `.claude/docs/terraform-patterns.md` 参照

## PRワークフロー

1. フィーチャーブランチを作成し、設定を変更
2. プッシュしてPRを作成 -> GitHub Actionsが`terraform plan`を実行し、コメントとして投稿
3. mainへのマージ後 -> 自動で`terraform apply`

## 認証

- **GitHub Appトークン**: 組織リポジトリ（推奨）
- **PAT**: 個人リポジトリ（`TERRAFORM_GITHUB_TOKEN`）
- **AWS OIDC**: S3バックエンド（静的な認証情報なし）

## ステート管理

バックエンド: DynamoDBロック付きAWS S3。`moved`ブロックによる移行。

## モジュールパラメータ

主要パラメータ: `repository`（必須）, `owner`, `description`, `visibility`, `default_branch`, `topics`, `branch_rulesets`（推奨）, `branches_to_protect`（レガシー）

完全なリファレンス: `.claude/docs/terraform-patterns.md` 参照

## コーディング標準

### 命名規則

- **ディレクトリ/モジュール**: kebab-case（例: `local-workspace-provisioning`）
- **変数/リソース**: snake_case（例: `repository_ruleset`）

### HCLスタイル

- 2スペースインデント
- コミット前に必ず`terraform fmt`を実行
- HashiCorp公式スタイルガイドに従う

## 検証

```bash
just validate                    # 設定を検証
just plan                        # 変更をプラン（追加/変更/削除を表示）
aws-vault exec portfolio -- just plan  # AWS認証付き
```

PRにはプラン出力のサマリーを含める必要あり。破壊的変更は明確に記載。

## コミットガイドライン

**Conventional Commits**に従う: `feat:`, `fix:`, `chore:`, `refactor:` など。

PRには次を含める: 目的/スコープ、影響するリポジトリ/ルール、関連issue、プランサマリー。

## 重要な指示

- 求められたことを実行する。それ以上でもそれ以下でもない
- 絶対に必要でない限り、ファイルを作成しない
- 常に新しいファイルを作成するより既存ファイルを編集することを優先
- 明示的に要求されない限り、ドキュメントファイルを積極的に作成しない
- 変更を加える前に既存のコードを読んでパターンを理解する
- 最小限の焦点を絞った変更を行う
- `terraform/src/repository/`でのすべての変更は`terraform plan`で検証が必要

## 参照

- 詳細コマンド: `.claude/docs/commands-reference.md`
- HCLパターン: `.claude/docs/terraform-patterns.md`
- ドキュメントガイドライン: `.claude/docs/documentation-guidelines.md`
