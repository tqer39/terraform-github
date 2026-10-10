# ドキュメントの規約

## 言語と命名

- リポジトリ内の Markdown 文書は日本語で記述する
- コマンド、識別子、ファイル名、製品名、API 名は必要に応じて原表記を使う
- ファイル名は用途を表す通常の `.md` に統一し、言語別の複製を作らない
- 説明が実装と一致するように、関連する既存文書を更新する
- 開発日記や作業中の計画を保管する専用ディレクトリは作らない

## 配置

| 配置場所 | 用途 |
| --- | --- |
| `README.md` | 概要、セットアップ、主要な操作 |
| `docs/*.md` | Terraform の操作と設計 |
| `docs/rules/*.md` | LLM が参照する共通ルールの原本 |
| `.rulesync/rules/*.md` | 原本への参照を生成するための入力 |

## LLM 向けルールの更新

ルールごとに `docs/rules/*.md` を原本として作成・更新する。
プロジェクトの構成は `project.md`、開発作業は `development.md`、
コーディングは `coding-standards.md`、文書は `documentation.md` で管理する。
各 LLM の設定には規約を複製せず、原本を読み込む指示を配置する。

```bash
mise run rules:sync
mise run rules:check
mise run lint
```

`rulesync.jsonc` は Claude Code、Codex、GitHub Copilot、Devin のルールだけを生成する。
Codex と Devin は `AGENTS.md`、Copilot は `.github/copilot-instructions.md`、
Claude Code は `.claude/rules/*.md` を入口として使う。
Copilot の個別ルールは `.github/instructions/*.instructions.md`、
Devin の個別ルールは `.devin/rules/*.md` に生成する。
個別ルールは対応する `docs/rules/<ルール名>.md` の原本だけを参照する。
Claude Code のルート文書は生成しない。
生成された入口は直接編集せず、`.rulesync/rules/` の参照を更新して再生成する。
MCP、スキル、フック、権限の設定は rulesync の生成対象に含めない。

## 検証

Markdown を編集したら `mise run lint` を実行する。
技術的な動作変更には適切な回帰テストを追加し、最終差分とリンクを確認する。
