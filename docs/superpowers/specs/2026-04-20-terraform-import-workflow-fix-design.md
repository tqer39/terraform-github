# terraform-import ワークフロー修正 設計

## 背景

`terraform-import` ワークフロー ([実行例](https://github.com/tqer39/terraform-github/actions/runs/24634883912/job/72028457439)) が以下のエラーで失敗した:

```text
Error handling -chdir option: chdir ./terraform/src/repository: no such file or directory
```

原因: ワークフローが単一ステート時代の構造 (`terraform/src/repository` 単数形) を前提にしているが、実構造はリポジトリ別ステート分離 (`terraform/src/repositories/<repo>/`) に移行済み。各ディレクトリは `module "this"` を含む。

## 目的

workflow_dispatch で任意の既存 GitHub リポジトリを、対応する Terraform state に import できる状態に修正する。

## 対象外

- ディレクトリ `terraform/src/repositories/<repo>/` が未作成の場合の自動生成
- 単一ステート構造 (`module <name>` 可変) の維持。移行済みとして扱う

## 入出力仕様

### ワークフロー入力

| 入力 | 型 | 必須 | 説明 |
| ---- | -- | ---- | ---- |
| `repo` | string | ✅ | GitHub リポジトリ名 (= ディレクトリ名)。例: `blog` |

`module` 入力は削除する (モジュール名は `this` 固定)。

### 前提条件

- `terraform/src/repositories/${repo}/` が存在する
- `module "this"` が `../../../modules/repository` を参照している

## 実装方針

`terraform-github.yml` と認証・トークン取得ステップを揃える。`aws-actions/configure-aws-credentials` 直接指定をやめ、既存の composite action を使用。

### ジョブステップ

1. `actions/checkout`
2. `./.github/actions/aws-credential` (OIDC, role: `portfolio-terraform-github-deploy`)
3. `actions/create-github-app-token` (`GHA_APP_ID`, `GHA_APP_PRIVATE_KEY`)
4. `hashicorp/setup-terraform`
5. `terraform -chdir=./terraform/src/repositories/${repo} init -reconfigure`
6. import ステップ (下記)

### import 対象

`module.this.*` 配下の以下 4 種 + ruleset。全て `|| true` で冪等性確保 (既に state にある / リソース未作成の場合をスキップ)。

| リソース | import ID |
| ---- | ---- |
| `module.this.github_repository.this[0]` | `${repo}` |
| `module.this.github_branch_default.this` | `${repo}` |
| `module.this.github_actions_repository_permissions.this[0]` | `${repo}` |
| `module.this.github_branch_protection.this["main"]` | `${repo}:main` |

### Ruleset import

モジュールは 2 種類の ruleset リソースを持つ (排他):

- `github_repository_ruleset.default_main_protection[0]` — `disable_default_main_protection = false` のとき作成。`name = "main"`
- `github_repository_ruleset.this[<key>]` — `branch_rulesets` map のキーごと。キーがそのまま `name` になる (blog 例: `"main"`)

Terraform import ID は `<repo>:<ruleset_id>` (owner 不要)。ruleset_id は GitHub API から取得する。

ワークフロー内で以下を実行:

```bash
# GitHub App トークンで ruleset 一覧を取得し、ID を列挙
ruleset_ids=$(gh api "repos/tqer39/${REPO}/rulesets" --jq '.[].id')
for id in $ruleset_ids; do
  name=$(gh api "repos/tqer39/${REPO}/rulesets/${id}" --jq '.name')
  # 両方のアドレスに import を試行 (一方は失敗するが `|| true` で許容)
  terraform -chdir=... import "module.this.github_repository_ruleset.default_main_protection[0]" "${REPO}:${id}" || true
  terraform -chdir=... import "module.this.github_repository_ruleset.this[\"${name}\"]" "${REPO}:${id}" || true
done
```

- 所有者は `tqer39` 固定でハードコード (プロジェクトの前提)
- 対応する Terraform アドレスが無い ruleset に import を試みても `|| true` で無視される
- Ruleset が無い場合は for ループが回らず noop

### env

- `TF_VAR_github_token`: GitHub App トークン (`steps.app_token.outputs.token`)
  - PAT フォールバックは不要。App Token で import 可能

## エラーハンドリング

- 各 import は `|| true` でスキップ。終了コードは常に 0 にする
- init 失敗は job failure
- ruleset 取得 API 失敗時は warning を出して skip (import 全体を失敗させない)

## テスト計画

1. 既存リポジトリ `blog` で workflow_dispatch 実行し、全ステップが PASS することを確認
2. 実行後、`just plan` で blog の state に差分が出ないことを確認
3. ディレクトリ未作成のリポジトリ名を指定 → init でエラー終了を確認 (期待動作)

## 変更ファイル

- `.github/workflows/terraform-import.yml` — 全面書き換え

## 懸念・留意点

- ruleset ID 取得の GH API 呼び出しが増えるため、トークン権限に `repos:rulesets:read` 等が必要
- `github_repository_ruleset.this` の for_each キーと API 上の name が一致していることを前提とする (モジュール実装で保証されている)
