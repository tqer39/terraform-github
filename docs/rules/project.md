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

セットアップ: `./scripts/bootstrap.sh && mise run setup` / フォーマット: `mise run tf:fmt` / 検証: `mise run tf:validate` / 計画: `mise run tf:plan` / リント: `mise run dev:lint` / クリーン: `mise run tf:clean`

## リファレンス

- [コマンドリファレンス](../commands-reference.md): import, worktree, メンテナンス, 削除
- [Terraform パターン](../terraform-patterns.md): HCL パターン, モジュールパラメータ
- [ワークフローと認証](../workflow.md): PR ワークフロー, 認証, State 管理
- [コーディング規約](coding-standards.md): 命名規則, HCL スタイル, コミット規約
- [ドキュメントガイドライン](documentation.md): 言語とファイル構成
