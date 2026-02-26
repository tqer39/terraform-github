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
