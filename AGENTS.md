# Repository Guidelines

このドキュメントは、terraform-github リポジトリへの貢献者向けガイドです。Terraform を用いて GitHub リポジトリ群を管理し、GitHub Actions で適用します。短く正確に、既存の運用に沿って進めてください。

## プロジェクト構成 / モジュール

- `terraform/src/repository/`: 実体のスタック定義（各リポジトリ用の `*.tf` と `main.tf`）。
- `terraform/modules/repository/`: 再利用モジュール（ブランチ、保護、ルールセット等）。
- `.github/workflows/`: CI/CD（plan/apply、import、renovate、prek）。
- `scripts/`: 補助スクリプト（例: `scripts/set-common-github-secrets.sh`）。
- `docs/`: 運用ドキュメント。

## ビルド / テスト / 開発コマンド

- 事前準備: `prek install`
- フォーマット＆静的チェック: `prek run --all-files`
- Terraform 初期化: `terraform -chdir=terraform/src/repository init -reconfigure`
- 検証: `terraform -chdir=terraform/src/repository validate`
- 変更確認: `terraform -chdir=terraform/src/repository plan`
- AWS 認証下での実行例: `aws-vault exec $AWS_PROFILE -- terraform -chdir=terraform/src/repository plan`

## コーディング規約 / 命名

- Terraform(HCL): インデント2スペース、`terraform fmt` を厳守（prek で自動）。
- ディレクトリ名/モジュール名: kebab-case（例: `local-workspace-provisioning`）。
- 変数/リソース名: snake_case（例: `repository_ruleset`）。
- ファイル分割: 機能単位（例: `variables.tf`, `provider.tf`, `main.tf`）。

## テスト方針

- 主要な“テスト”は `validate` と `plan` の健全性確認です。
- PR には最新の `plan` 出力の要点（追加/変更/破壊）を要約してください。
- 破壊的変更は明示し、適用手段（Actions か手動）を記載。

## コミット / PR ガイドライン

- Conventional Commits を採用（例: `feat: ...`, `fix: ...`, `chore: ...`, `refactor: ...`）。
- PR には目的、影響範囲（対象リポジトリ/ルール）、関連 Issue、`plan` 要約を含める。
- 小さく一貫した変更単位で提出。スクリーンショットは不要（必要なら `plan` ログ）。

## セキュリティ / 設定

- 秘密情報はコミットしない。検出系フック（detect-aws-credentials, detect-private-key）を通過させる。
- 共通シークレットは `scripts/set-common-github-secrets.sh <owner>` で一括設定。
- GitHub App トークン/ AWS 認証は Actions で付与（ローカルは各自のプロファイルを使用）。

## エージェント向けメモ

- 無関係な差分を作らない。既存レイアウト・命名に厳密に合わせる。
- 変更は `terraform/src/repository` → `plan` で検証し、PR に要約を記載。
