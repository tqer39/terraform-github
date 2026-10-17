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

差分も警告もない `No changes` の自動 plan コメントは後続 job で削除します。
コメント一覧は全ページ取得し、30件を超える PR でも削除漏れを防ぎます。
削除対象は GitHub Actions bot が投稿した tfcmt の plan 結果だけです。
人のコメント、変更・警告・drift の詳細を含む結果は保持します。

## 認証方式

- **GitHub App トークン**: Organization リポジトリ（推奨）
- **Terraform CI / Import**: 専用 App `tqer39-terraform-github` の installation token
- **ローカル Terraform**: `github_token` 変数で明示した既存認証

専用 App の Client ID は `Iv23liAAVYfZee7FNR3m`、App ID は `5361381` です。
認証情報の原本は 1Password の `shared-secrets` Vault で管理します。
項目名は `GitHubApp`、セクション名は `tqer39-terraform-github` です。
フィールド名は `tqer39-terraform-github/client-id` と `tqer39-terraform-github/private-key` です。
フィールド名自体に `/` が含まれるため、CLI の参照には項目内の一意なフィールド ID を使用します。
CI は同期した Repository Variable `TERRAFORM_GITHUB_APP_CLIENT_ID` と
Actions Secret `TERRAFORM_GITHUB_APP_PRIVATE_KEY` を参照します。
秘密値をログやコマンド引数へ展開せず、標準入力で同期してください。
`TERRAFORM_GITHUB_TOKEN` と汎用の `GHA_APP_PRIVATE_KEY` は Terraform CI / Import で使いません。
汎用 App を使うほかのワークフローの認証は、この変更の対象外です。

App は Terraform 定義済みのリポジトリだけにインストールします。
Administration・Environments・Secrets・Variables は読み書き、Contents は読み取りが最大権限です。
現在の定義にブランチ新規作成はないため、Contents の書き込みは要求しません。
新しい管理対象は、先に App のインストール先へ追加する必要があります。
個人アカウントの新規リポジトリ作成は、installation token が対応する API の制約を別途確認してください。

`.github/scripts/app_token_scope.py` が各 shard の対象名と実行種別からトークンの範囲を決めます。
PR、共通変更の main push、Import、plan の手動実行は読み取りだけです。
main の apply 時だけ書き込みを要求し、main 以外の apply はトークン発行前に拒否します。
Environments・Secrets・Variables は kazokubi が対象に含まれるときだけ要求し、
kazokubi を apply しない main push では読み取りに制限します。
App の秘密鍵自体はトークン発行 Action だけに渡し、Terraform には短命のトークンだけを渡します。
トークンはジョブ終了時に Action の後処理で失効します。

固定した `actions/create-github-app-token` v3 の metadata に Variables 入力がないため、
同版が実装する permission 環境入力 `INPUT_PERMISSION-ACTIONS-VARIABLES` で明示します。
上流の入力解析を固定版で検証し、App の全権限を暗黙に継承しないようにしています。
App の登録・権限・インストール先は GitHub Settings で管理し、Terraform 自身の管理対象外です。

- **AWS OIDC**: S3 バックエンド（静的認証情報不要）

## State 管理

バックエンド: AWS S3 + DynamoDB ロック。マイグレーションは `moved` ブロックで実施。

## Renovate validator の固定版とキャッシュ

[Issue #1753](https://github.com/tqer39/terraform-github/issues/1753) の対策として、
`lefthook.yml` の npm package 指定で Renovate のバージョンを固定します。
ローカル hook と CI は同じコマンドを実行します。
`renovate.json5` の regex custom manager が固定版の更新を検出します。

取得先は npm cache に統一します。通常の開発依存への追加は行わず、
既存の pnpm lockfile と audit の依存範囲を維持します。
[npm exec の仕様](https://docs.npmjs.com/cli/v11/commands/npm-exec/) に従い、
キャッシュには配布物と npx の実行用依存を保存します。
`--prefer-offline` で再取得を減らします。空のキャッシュでは取得が必要です。
上流依存の deprecated 警告は固定化だけでは解消しません。

CI は `NPM_CONFIG_CACHE` で runner の一時ディレクトリに取得先を固定し、
`actions/cache` でその全体を保存します。キーは OS・CPU・実際の Node バージョン・
hook から読み取った Renovate バージョンです。異なる版への fallback は使いません。
cache hit でも validator を含む全 lint を実行します。

計測は `pnpm install --frozen-lockfile` と provider の初期化後、
各回で空の一時 npm cache を指定して `mise run lint` を実行し、
同じキャッシュを再利用して再実行します。この組を3回繰り返します。
lint 総時間はコマンドの経過時間、validator 時間は lefthook の summary で確認します。
GitHub Actions の lint job 総時間には cache の復元・保存や setup も含まれるため、
ローカルの測定値とは分けて評価してください。

2026-10-11 に macOS arm64、Node 24.21.0、npm 11.19.0、
Renovate 44.149.3 で測定した結果は以下のとおりです。時間の単位は秒です。

| 回 | miss: lint 総時間 | hit: lint 総時間 | miss: validator | hit: validator |
| --- | --- | --- | --- | --- |
| 1 | 22.62 | 7.80 | 17.88 | 1.38 |
| 2 | 22.42 | 7.64 | 17.32 | 1.18 |
| 3 | 24.51 | 7.82 | 19.85 | 1.20 |
| 平均 | 23.18 | 7.75 | 18.35 | 1.25 |

ローカルでの平均短縮率は lint 総時間が約67%、validator が約93%でした。
6回すべて全 lint が成功し、各回で Python の回帰テスト29件と
Terraform モジュールテスト6件も成功しました。
固定版の実コマンドで正常設定の終了コード0と、`enabled` に文字列を渡す
不正設定の終了コード1を確認しました。frozen install と Terraform validate も成功しました。
GitHub Actions 上の cache 転送時間や lint job 総時間の短縮量は未計測です。
ローカルの npm cache は約673 MiB だったため、CI の復元・保存コストも確認してください。

`aws-vault exec portfolio` と既存の GitHub 認証で Terraform plan を実行し、
`No changes` を確認しました。今回 Terraform 設定や共有 state の変更はありません。

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
`sprintf-js` の moderate 警告も、以下の対策で依存経路を除去しました。

## YAML 解析依存の sprintf-js 対策

[GHSA-hp3w-g68c-fv3c](https://github.com/advisories/GHSA-hp3w-g68c-fv3c) は、
外部から指定される format string の過大な precision による例外です。
経路は `rulesync → gray-matter → js-yaml 3 → argparse 1 → sprintf-js` でした。
通常の frontmatter 解析では脆弱なモジュールの読み込みを確認しませんでしたが、
未修正の依存を残さず、`js-yaml@3>argparse` だけを `2.0.1` に固定します。

argparse 2 は sprintf-js に依存せず、
[旧 API の互換機能](https://github.com/nodeca/argparse/blob/master/doc/migrate_v2_to_v3.md)
を維持しています。依存全体を argparse 3 に置き換えることはしません。
互換 API の利用時は非推奨警告が出ます。旧 version オプションの互換不具合には、
js-yaml CLI で parser.version を明示する固定パッチを適用し、標準出力への表示を保持します。
回帰テストで frontmatter 解析、CLI の help・version・相互変換、
不正 YAML と存在しないファイルの終了コード、sprintf-js の依存除去を確認します。
rulesync の生成・検証と包括 lint、除外なしの pnpm audit も実行します。

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
モジュール、共通 Action、shard スクリプト、対象選択、ワークフロー、Terraform・tfcmt バージョンの
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

ローカルと CI は `mise.toml` に固定した tfcmt 4.14.19 を使用します。
旧セットアップ Action の固定版3.2.1は抑制オプションに対応しないため、mise に統一します。
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
