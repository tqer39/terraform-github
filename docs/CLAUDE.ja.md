# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。

## リポジトリ概要

これは、TerraformとGitHub Actionsを使用してGitHubリポジトリを管理するためのTerraform Infrastructure as Code (IaC) プロジェクトです。このリポジトリは、モジュラーアーキテクチャを使用して、複数のGitHubリポジトリの作成、設定、保護を自動化します。

## アーキテクチャ

### モジュールベース設計

コードベースは、再利用可能なモジュールとリポジトリ固有の設定を明確に分離しています：

- **`terraform/modules/repository/`**: GitHubリポジトリ管理のための中核となる再利用可能なTerraformモジュール
  - `github_repository.tf`: リポジトリの作成と設定
  - `github_branch_protection.tf`: 従来のブランチ保護（レガシー、段階的に廃止予定）
  - `github_repository_ruleset.tf`: 最新のリポジトリルールセット（推奨アプローチ）
  - `github_actions_repository_permissions.tf`: GitHub Actionsの権限管理
  - `github_branch.tf` & `github_branch_default.tf`: ブランチ作成とデフォルトブランチ管理

- **`terraform/src/repository/`**: リポジトリ固有の設定
  - 各`.tf`ファイルは単一のGitHubリポジトリを表す
  - リポジトリ固有のパラメータでコアモジュールを使用
  - `terraform.tf`: S3ステート保存を使用したバックエンド設定
  - `moved`ブロックはアンダースコアからハイフンへの命名規則のリファクタリングを示す

### CI/CD統合

- **`.github/workflows/`**: GitHub Actionsワークフロー
  - `terraform-github.yml`: plan/applyのメインワークフロー（PRトリガー）
  - `terraform-import.yml`: 既存リポジトリのインポート
  - `pre-commit.yml`: コード品質チェック

- **`.github/actions/`**: 再利用可能なアクションコンポーネント
  - `setup-terraform`: 初期化とフォーマットチェック
  - `terraform-validate`: 検証とリンティング
  - `terraform-plan`: tfcmtによるPRコメント付きプラン
  - `terraform-apply`: デプロイメント追跡付き変更適用

## 一般的なコマンド

### Terraformオペレーション

```bash
# すべてのTerraformファイルをフォーマット
terraform fmt -recursive

# Terraformの初期化（terraform/src/repository/で実行する必要があります）
cd terraform/src/repository
terraform init -upgrade

# 設定の検証
terraform validate

# 変更のプラン
terraform plan

# 変更の適用（主にGitHub Actions経由で実行）
terraform apply -auto-approve

# 既存リポジトリリソースのインポート
terraform import module.<module_name>.github_repository.this <repo_name>
terraform import module.<module_name>.github_branch_default.this <repo_name>
terraform import module.<module_name>.github_actions_repository_permissions.this <repo_name>
terraform import module.<module_name>.github_branch_protection.this[\"<branch_name>\"] <repo_name>:<branch_name>
```

### コード品質

```bash
# すべてのpre-commitフックを実行
pre-commit run --all-files

# 特定のフックを実行
pre-commit run terraform_fmt --all-files
pre-commit run terraform_validate --all-files
pre-commit run terraform_tflint --all-files
pre-commit run yamllint --all-files
pre-commit run markdownlint --all-files

# モジュールサポート付きTFLint
tflint --init
tflint --chdir=terraform/src/repository --call-module-type=all
```

### リポジトリ管理

```bash
# リポジトリ間で共通シークレットを設定
./scripts/set-common-github-secrets.sh <github_owner>
```

## 新しいリポジトリの追加

1. `terraform/src/repository/`に新しい`.tf`ファイルを作成（例：`my-new-repo.tf`）
2. ニーズに基づいて適切なパターンを使用：

### 最新のアプローチ（リポジトリルールセット）

```hcl
module "my_new_repo" {
  source = "../../modules/repository"

  github_token    = var.github_token
  repository      = "my-new-repo"
  owner           = "AIPairStudio"  # オプション：組織名
  description     = "リポジトリの説明"
  default_branch  = "main"
  visibility      = "public"  # または "private"
  topics          = ["terraform", "automation"]

  # 最新のリポジトリルールセット（推奨）
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

### レガシーアプローチ（ブランチ保護）

```hcl
module "my_legacy_repo" {
  source = "../../modules/repository"

  github_token    = var.github_token
  repository      = "my-legacy-repo"
  description     = "リポジトリの説明"
  default_branch  = "main"
  topics          = ["terraform", "automation"]

  # レガシーブランチ保護（まだサポートされています）
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

## 主要なワークフロー

### プルリクエストワークフロー

1. フィーチャーブランチを作成し、リポジトリ設定を変更
2. ブランチをプッシュしてPRを作成
3. GitHub Actionsが自動的に：
   - OIDC経由でAWS認証情報を取得
   - GitHub Appトークンを生成（または個人リポジトリではPATを使用）
   - tfcmtを使用して`terraform plan`を実行し、PRコメントとして投稿
   - プラン結果をPRコメントとして投稿
4. mainへのマージ後：
   - 同じ認証フロー
   - 自動的に`terraform apply`を実行
   - デプロイメントステータスを追跡

### 既存リポジトリのインポート

1. Actionsタブ → "Terraform Import"ワークフローに移動
2. パラメータを指定して"Run workflow"をクリック：
   - `module`: モジュール名（例：`my_repo`）
   - `repo`: GitHubリポジトリ名
3. ワークフローがインポート：
   - リポジトリ設定
   - デフォルトブランチ
   - Actions権限
   - ブランチ保護ルール

## 認証戦略

プロジェクトは複数の認証方法をサポート：

- **GitHub Appトークン**: 組織リポジトリ用（推奨）
- **個人アクセストークン（PAT）**: 個人リポジトリ用（`TERRAFORM_GITHUB_TOKEN`）
- **GitHub Actionsトークン**: ワークフローオペレーション用の標準`GITHUB_TOKEN`
- **AWS OIDC**: S3バックエンド用の一時的な認証情報（長期的なキーなし）

## ステート管理

- バックエンド: DynamoDBロック付きAWS S3
- ステートファイル: `terraform/src/repository/terraform.tfstate`
- 設定: `terraform/src/repository/terraform.tf`
- 移行: リファクタリング用の`moved`ブロックで処理

## セキュリティに関する考慮事項

- すべてのトークンはGitHub Actionsシークレットとして管理
- OIDC経由のAWS認証（静的な認証情報なし）
- Pre-commitフックがシークレットとプライベートキーを検出
- ブランチ保護がコードレビューを強制
- リポジトリルールセットが細かいアクセス制御を提供

## モジュールパラメータリファレンス

リポジトリモジュールの主要パラメータ：

- `repository`: リポジトリ名（必須）
- `owner`: 組織名（オプション、デフォルトは個人アカウント）
- `description`: リポジトリの説明
- `visibility`: `public`または`private`
- `default_branch`: デフォルトブランチ名（通常は`main`）
- `topics`: リポジトリのトピック/タグのリスト
- `branch_rulesets`: 最新のルールベース保護（推奨）
- `branches_to_protect`: レガシーブランチ保護（後方互換性）
- `has_wiki`, `has_issues`, `has_projects`: 機能トグル
- `allow_merge_commit`, `allow_squash_merge`, `allow_rebase_merge`: マージ戦略

## ドキュメント構造とガイドライン

### ドキュメントファイルの整理方法

- **プロジェクトルート** (`*.md`): 英語でのドキュメント
  - `README.md`: プロジェクトの概要（英語）
  - `CONTRIBUTING.md`: 貢献ガイドライン（英語）
  - `CHANGELOG.md`: 変更履歴（英語）
  - `CLAUDE.md`: AI アシスタント向けガイダンス（日本語）

- **日本語ドキュメント** (`./docs/*.ja.md`): 日本語でのドキュメント
  - `./docs/README.ja.md`: プロジェクトの概要（日本語）
  - `./docs/CONTRIBUTING.ja.md`: 貢献ガイドライン（日本語）
  - `./docs/architecture.ja.md`: アーキテクチャ詳細（日本語）
  - `./docs/troubleshooting.ja.md`: トラブルシューティング（日本語）

### ドキュメント作成時の処理ディレクトリ

1. **英語ドキュメント**: プロジェクトルートに配置
2. **日本語ドキュメント**: `./docs/` ディレクトリに `.ja.md` 拡張子で配置
3. **多言語対応**: 必要に応じて `./docs/` 内にロケール別サブディレクトリを作成

### ドキュメント管理のベストプラクティス

- プロジェクトの主要ドキュメントは英語を標準とする
- 日本語ドキュメントは補完的な役割として `./docs/` 内に配置
- ファイル名は明確で一貫性を保つ
- 更新時は対応する言語版も同期を取る

### 開発日誌

- **目的**: 重要な変更とその理由を記録し、技術的決定と実装詳細を文書化し、遭遇した問題と解決策を追跡し、将来の開発者にコンテキストを提供する
- **作成ルール**:
  - 未コミットの変更や前回のコミットから文書化されていない作業がある場合、新しい日誌エントリを作成する
  - ファイル名は `docs/dev-diary/YYYY-MM-DD.md` 形式に従う
  - 今日の日付のファイルが存在しない場合、自動的にファイルを作成する
  - 最後の日誌エントリ以降のすべての開発作業を文書化する
- **形式要件**: 各日誌エントリには以下を含める：
  - 作業の概要
  - 実装詳細
  - テスト結果
  - 問題と解決策
  - 今後の検討事項
  - 開発者の気持ちと反省
  - 潜在的なリファクタリング機会
- **タイミング**: 開発セッションの最後または要求された時に日誌エントリを作成する

## 重要な指示の備忘録

求められたことを実行し、それ以上でもそれ以下でもないこと。
目標達成に絶対必要でない限り、ファイルを作成しないこと。
常に新しいファイルを作成するよりも既存のファイルを編集することを優先する。
ドキュメントファイル（*.md）やREADMEファイルを積極的に作成しないこと。ユーザーから明示的に要求された場合のみドキュメントファイルを作成する。

## リポジトリ削除時の手順

- `aws-vault exec portfolio` を使用して、適切な AWS 認証情報を取得し、Terraform の tfstate からリソース・モジュール削除します。
- `portfolio` は `~/.aws/config` で設定された SSO ロールの AWS プロファイル名です。

```shell
aws-vault exec portfolio -- terraform -chdir=./terraform/src/repository state rm  module.sample-repository
Removed module.sample-repository.data.github_user.tqer39
Removed module.sample-repository.github_actions_repository_permissions.this[0]
Removed module.sample-repository.github_branch_default.this
Removed module.sample-repository.github_repository.this
Successfully removed 4 resource instance(s).
```

- 関連ソースコード `terraform/src/repository/sample-repository.tf` を削除します。
- GitHub リポジトリを削除します。

```shell
gh repo delete tqer39/sample-repository --confirm
```
