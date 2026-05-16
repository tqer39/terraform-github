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

セットアップ: `./scripts/bootstrap.sh && mise install && mise run setup` / フォーマット: `mise run tf:fmt` / 検証: `mise run tf:validate` / 計画: `mise run tf:plan` / リント: `mise run dev:lint` / クリーン: `mise run tf:clean`

## 必須ルール

- 依頼されたことだけを行う。それ以上もそれ以下もしない
- ファイルの新規作成は最小限に。既存ファイルの編集を優先する
- 変更前に既存コードを読み、パターンを理解する
- **Conventional Commits** に準拠（`feat:`, `fix:`, `chore:`, `refactor:`）
- 変更時は必ず検証: `mise run tf:validate && mise run tf:plan`
- 新規 repo 追加時に `disable_default_main_protection` を指定しなければ、モジュールデフォルトで標準 main 保護（force push 禁止 / 削除禁止 / PR 必須 / linear history / `workflow-result` 必須 / 承認 0 / 所有者 bypass）が自動適用される

## リファレンス

- [コマンドリファレンス](docs/commands-reference.md): import, worktree, メンテナンス, 削除
- [Terraform パターン](docs/terraform-patterns.md): HCL パターン, モジュールパラメータ
- [ワークフローと認証](docs/workflow.md): PR ワークフロー, 認証, State 管理
- [コーディング規約](docs/coding-standards.md): 命名規則, HCL スタイル, コミット規約
- [ドキュメントガイドライン](docs/documentation-guidelines.md): ファイル構成, 開発日記
