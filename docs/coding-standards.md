# コーディング規約

## 命名規則

- **ディレクトリ/モジュール**: kebab-case（例: `local-workspace-provisioning`）
- **変数/リソース**: snake_case（例: `repository_ruleset`）

## HCL スタイル

- 2スペースインデント
- コミット前に必ず `terraform fmt` を実行
- HashiCorp スタイルガイドに準拠

## バリデーション

```bash
just validate                              # 設定の検証
just plan                                  # 変更の計画
aws-vault exec portfolio -- just plan      # AWS 認証付き
```

## コミット規約

**Conventional Commits** に準拠: `feat:`, `fix:`, `chore:`, `refactor:` 等

## PR 要件

PR には以下を含めること: 目的/スコープ、影響するリポジトリ/ルール、関連 Issue、plan サマリ。

## 新規リポジトリ追加時の標準 main ブランチ保護

モジュールを呼ぶだけで `main` の標準保護が**自動で**作成される（opt-out 方式）。

自動適用されるルール:

- force push 禁止（`non_fast_forward`）
- ブランチ削除禁止（`deletion`）
- linear history 必須（`required_linear_history`）
- PR 必須、承認数 0（1 人開発向け）
- 必須ステータスチェック: `workflow-result`
- 所有者 bypass 有効（`bypass_mode = "pull_request"`）

`disable_default_main_protection` を明示しない限り、この保護は常に有効になる。
archived リポジトリや保護が不要なリポジトリには `disable_default_main_protection = true` を指定すること。
