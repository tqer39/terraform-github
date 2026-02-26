# ワークフローと認証

## リポジトリの追加

1. `terraform/src/repositories/<repo-name>/` 配下にディレクトリを作成
2. `../../../modules/repository` モジュールを必須パラメータ付きで使用
3. `just validate && just plan` を実行
4. PR を作成してレビュー依頼

HCL パターンとモジュールパラメータの詳細: [terraform-patterns.md](terraform-patterns.md) を参照

## PR ワークフロー

1. feature ブランチを作成し、設定を変更
2. push して PR を作成 → GitHub Actions が `terraform plan` を実行し、コメントとして投稿
3. main にマージ後 → 自動で `terraform apply` が実行

PR には plan 出力のサマリを含めること。破壊的変更は明示的にマークすること。

## 認証方式

- **GitHub App トークン**: Organization リポジトリ（推奨）
- **PAT**: 個人リポジトリ（`TERRAFORM_GITHUB_TOKEN`）
- **AWS OIDC**: S3 バックエンド（静的認証情報不要）

## State 管理

バックエンド: AWS S3 + DynamoDB ロック。マイグレーションは `moved` ブロックで実施。
