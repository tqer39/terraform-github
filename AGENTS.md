# terraform-github

Terraform IaC で GitHub リポジトリを管理するプロジェクト。モジュラーアーキテクチャと GitHub Actions による自動化。

## 主要パス

| パス | 用途 |
| ---- | ---- |
| `terraform/modules/repository/` | 再利用モジュール（リポジトリ, Rulesets, Environments, Actions） |
| `terraform/src/repositories/` | リポジトリ別設定（1リポジトリ1ディレクトリ） |
| `.github/workflows/` | CI/CD（plan/apply, import, pre-commit） |
| `.github/actions/` | 再利用アクション（setup, validate, plan, apply） |

## 主要コマンド

セットアップ: `make bootstrap && just setup` / フォーマット: `just fmt` / 検証: `just validate` / 計画: `just plan` / リント: `just lint` / クリーン: `just clean`

## 必須ルール

- 依頼されたことだけを行う。それ以上もそれ以下もしない
- ファイルの新規作成は最小限に。既存ファイルの編集を優先する
- 変更前に既存コードを読み、パターンを理解する
- **Conventional Commits** に準拠（`feat:`, `fix:`, `chore:`, `refactor:`）
- 変更時は必ず検証: `just validate && just plan`

## リファレンス

- [コマンドリファレンス](docs/commands-reference.md): import, worktree, メンテナンス, 削除
- [Terraform パターン](docs/terraform-patterns.md): HCL パターン, モジュールパラメータ
- [ワークフローと認証](docs/workflow.md): PR ワークフロー, 認証, State 管理
- [コーディング規約](docs/coding-standards.md): 命名規則, HCL スタイル, コミット規約
- [ドキュメントガイドライン](docs/documentation-guidelines.md): ファイル構成, 開発日記
