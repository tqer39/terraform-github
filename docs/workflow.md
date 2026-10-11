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

## Terraform CI の shard 実行

対象 root を名前順で最大5つの shard に均等分配します。各 runner で checkout、
AWS OIDC 認証、Terraform・TFLint・tfcmt のセットアップを1回だけ実行し、
shard 内では root を順次 fmt / init / validate / lint / plan します。
単一 root は1ジョブ、対象がなければ Terraform ジョブを省略します。

state のバックエンド設定、`tfplan` の保存先、tfcmt の `target` は root ごとに保持します。
失敗した root は後続処理へ進まず、他 root の検証を続けて shard 全体を失敗させます。
`fail-fast: false` と `workflow-result` で、別 shard の検証と必須チェックの失敗を維持します。

通常 CI は `terraform init -input=false -lockfile=readonly` で固定 provider を使います。
依存更新の `-upgrade` は `terraform-renovate.yml` で別に実行します。
provider cache は OS・CPU・Terraform バージョン・shard・lockfile ハッシュをキーにし、
runner 内の1つの Terraform process だけが更新します。
[公式の cache 仕様](https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache)
に従い、state、`.terraform`、plan は cache や計測 artifact に含めません。

root 単独の変更は main push で保存した `tfplan` を apply します。
モジュール、共通 Action、shard スクリプト、対象選択、ワークフロー、Terraform バージョンの
共有変更は全 root の plan を実行し、自動 apply を禁止します。
ただし PR と main push では、比較元と変更後の両方で `main.tf` の
`module "this"` に `archived = true` を設定済みの root を除外します。
判定はコミット済みの設定を使い、標準形式のリテラル値だけを認識します。
archive への変更・解除・新規追加は対象に残り、必要な plan / apply を実行します。
GitHub の実状態は照会しないため、設定との差を確認・修復する場合は手動実行してください。
`workflow_dispatch` の個別指定と `repository: all` は archive 済みの root も対象に含めます。
plan を確認してから `workflow_dispatch` で `repository` と `apply: true` を指定してください。
手動実行でも同じ実行内で新しく保存した plan だけを apply し、再計画による apply は行いません。
PR でレビューした別 run の plan を転送する仕組みではありません。

### plan コメントの抑制

`tfcmt plan -skip-no-changes` で、警告のない `No changes` と
`Plan: 0 to add, 0 to change, 0 to destroy.` の個別コメントを抑制します。
リソースのアドレス移動や output の変更だけの場合もリソース増減はゼロになるため、
完全に変更がないとは限りません。plan の保存と必要な apply は継続し、
実行結果は shard の job summary、詳細は CI ログで確認できます。
警告・エラーやリソースの増減がある plan は引き続きコメントします。

以前の実行や `-patch` で更新されたゼロ件コメントは CI の最後に削除します。
全ページを取得し、このワークフローの tfcmt メタデータが付いた
`github-actions[bot]` の plan コメントだけを対象にします。警告・エラーを含むコメントは残します。

### 性能と API 制限の計測

各 shard の job summary と `terraform-metrics-<shard>` artifact に、root の結果・
最終処理段階・秒数と、provider PAT の API rate-limit の実行前後の値を保存します。
認証トークン、state、plan 本体は保存しません。PAT は他の実行と API 予算を共有するため、
remaining の差はこの run だけのリクエスト数ではありません。
reset の変化、並行 run、secondary rate limit による失敗もログと併せて確認してください。

[変更前 run 38014243938](https://github.com/tqer39/terraform-github/actions/runs/38014243938)
の Issue #1754 計測値は、workflow 273秒（API の timestamp 差は272秒）、
Terraform ジョブ群231秒、
41ジョブ合計1001 runner秒です。変更後の全 root の PR run で、以下を比較します。
キャッシュなしの初回と cache がある再実行を分け、root 数と plan 内容も確認してください。

```bash
gh api repos/tqer39/terraform-github/actions/runs/RUN_ID > /tmp/run.json
gh api --paginate --slurp \
  repos/tqer39/terraform-github/actions/runs/RUN_ID/jobs > /tmp/jobs.json
python3 .github/scripts/ci_metrics.py /tmp/run.json /tmp/jobs.json
gh run download RUN_ID --pattern 'terraform-metrics-*' --dir /tmp/terraform-metrics
```

workflow の時間は attempt の開始から最終ジョブ終了まで、Terraform ジョブ群の時間は最初の開始から
最後の終了まで、runner秒は各ジョブの開始から終了までの合計で比較します。
これは課金時間ではありません。再実行は attempt ごとに取得し、混在させないでください。
変更前 run には PAT rate-limit の計測値がないため、過去の API 使用量は復元できません。
最大同時実行数は5のまま維持し、API 制限の改善は新しい実測値が揃うまで断定しません。

2026-10-11 の [初回 shard run 38101259781](https://github.com/tqer39/terraform-github/actions/runs/38101259781)
は全42 root と `workflow-result` が成功しました。

| 計測項目 | 変更前 | 初回 shard | 差 |
| --- | ---: | ---: | ---: |
| root 数 | 41 | 42 | +1 |
| Terraform ジョブ数 | 41 | 5 | -36 |
| workflow 秒（API timestamp） | 272 | 110 | -162 |
| Terraform ジョブ群の秒 | 231 | 85 | -146（約63%） |
| Terraform runner秒 | 1001 | 406 | -595（約59%） |

provider cache は5 shard とも未取得で開始し、37 root の init は同じ runner の
cache を再利用しました。各 shard の provider cache 保存も成功しています。
全42 root の plan のうち41 root はリソース変更なし、`blog` のみ追加2・変更2・削除0でした。
`blog` は既存設定と実環境の差で、archive 解除・public 化などを含みます。
今回の共有変更では自動 apply されないため、適用は別途 plan をレビューしてください。

5 shard の PAT rate-limit の core は前後とも remaining 5000・used 0 でしたが、
reset が変わっており、消費ゼロの証拠としては扱いません。
primary / secondary rate-limit エラーはログで検出されませんでした。
変更前の API 計測値がないため使用量の増減は未確認です。
root 数・provider 更新の有無・runner 性能が異なる run の比較であり、
単一計測からすべての実行で同じ短縮率になるとは判断しません。
