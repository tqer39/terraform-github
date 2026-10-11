# ワークフローと認証

## リポジトリの追加

1. `terraform/src/repositories/<repo-name>/` 配下にディレクトリを作成
2. `../../../modules/repository` モジュールを必須パラメータ付きで使用
3. `mise run tf:validate && mise run tf:plan` を実行
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

## 開発依存の深い brace pattern 対策

[Issue #1755](https://github.com/tqer39/terraform-github/issues/1755) の
[GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm) は、
`braces@3.0.3` の深い入力による再帰処理のスタック枯渇です。
2026-10-10 時点で公式 advisory に修正版はありません。

依存経路は以下のとおりです。いずれも開発用の依存です。

- `markdownlint-cli2@0.23.3 → micromatch@4.0.8 → braces@3.0.3`
- `markdownlint-cli2@0.23.3 → globby@16.2.4 → fast-glob@3.3.3 → micromatch → braces`
- `rulesync@29.0.0 → globby → micromatch / fast-glob → braces`

lefthook の Markdown lint は `{staged_files}` を glob 引数として渡します。
ローカルではステージされたファイル名、CI の `mise run lint` では PR に含まれる
追跡ファイル名が外部入力になります。ファイル名に brace が含まれる場合、
glob 展開を通じて本処理に届きます。Markdown の本文は glob pattern にはなりません。
ルール生成もルールの検索に glob を使うため、PR 内の設定・ルール名は信頼済みと仮定しません。
影響は lint とルール生成の失敗で、Terraform provider や管理対象の実行依存ではありません。

`pnpm-workspace.yaml` の override で全経路の `braces` を
[`@dieub/braces-depth-guard@3.0.3-pn.3`](https://github.com/dieub/braces-depth-guard/tree/305a2e4bfe324bb53c336c1b03387ee1251c926f)
へ置換します。これは公式修正版ではなく、MIT ライセンスを保持した派生パッケージです。
公開 registry の配布物を上流 3.0.3 と比較し、文字列解析と AST の
compile / expand / stringify に深さ 100 の上限があることを確認しました。
深さ超過は明示的なエラーで拒否し、lint は失敗として報告します。
展開結果の総数や任意の不正な AST 全般を制限する対策ではありません。

公開 provenance に記録されたソースはコミット
`305a2e4bfe324bb53c336c1b03387ee1251c926f`、タグは `3.0.3-pn.3` です。
配布物の SHA-512 は `pnpm-lock.yaml` の integrity に固定します。
配布物ハッシュと provenance の記録、配布された実コードとこのコミットの一致を確認し、
同コミットの上流互換・深さ制限テスト 799 件を実行して成功しました。
配布物の README には未公開候補との古い記述が残っていますが、採用版は registry に
公開された固定版です。上流の正式修正版が公開された際には再評価して override を解除します。

`tests/test_dependencies.py` は通常の選択肢・範囲・ネスト・エスケープ、両依存経路、
深い文字列と直接 AST、実際のファイル名、Markdown lint の自動修正とエラーを検証します。
既存のルール生成テストも `mise run lint` で継続します。
採用時の全 lint、リポジトリの回帰テスト 27 件、Terraform モジュールテスト 6 件、
`mise run tf:validate` は成功しました。`mise run tf:plan` は AWS 認証がなく
S3 バックエンドを初期化できなかったため未完了です。Terraform の設定変更はありません。

```bash
pnpm install --frozen-lockfile
pnpm why braces
mise run lint
pnpm audit --json
```

置換後の audit では本 advisory と high の警告が解消しました。audit の除外設定は使いません。
変更前から存在する `sprintf-js` の moderate 警告
[GHSA-hp3w-g68c-fv3c](https://github.com/advisories/GHSA-hp3w-g68c-fv3c) は別件で残っています。
audit 全体の終了コードはこの警告により失敗になるため、本 advisory の有無も確認してください。
