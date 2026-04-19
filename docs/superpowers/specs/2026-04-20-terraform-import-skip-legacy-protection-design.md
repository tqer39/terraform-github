# terraform-import ワークフロー: ruleset 管理リポジトリでの legacy branch_protection import スキップ 設計

## 背景

`terraform-import` ワークフロー ([実行例: run 24635657942](https://github.com/tqer39/terraform-github/actions/runs/24635657942)) は job 全体としては成功するが、`Terraform Import (core resources)` step のログに以下のエラーが記録されている:

```text
Error: Configuration for import target does not exist

The configuration for the given import module.this.github_branch_protection.this["main"] does not exist.
All target instances must have an associated configuration to be imported.
```

該当リポジトリ: `claude-code-remote`（他にも `disable_default_main_protection = true` を指定したリポジトリ全てで同じログが出る）。

## 原因

- `.github/workflows/terraform-import.yml:62` は全リポジトリに対し無条件で `module.this.github_branch_protection.this["main"]` の `terraform import` を実行する
- 一方 `terraform/src/repositories/claude-code-remote/main.tf` は `disable_default_main_protection = true` を指定し、legacy `github_branch_protection` ではなく `branch_rulesets` (ruleset ベース) で main 保護を行う
- そのため module 側では `github_branch_protection.this` リソースが `for_each = var.branches_to_protect`（空）で生成されず、import target の config が不在となって terraform が exit 1 する
- 各 import 行には `|| true` が付いているため step の exit code 自体は 0 になり、job は success となる

## 現状影響

- 機能影響なし（import 自体は他のリソースで成功している）
- ログノイズとして残り、本物のエラーの見落としリスクがある
- `disable_default_main_protection = true` を持つリポジトリでは常に発生する

## 目的

ruleset ベースで保護されたリポジトリでは `github_branch_protection` の import を行わず、不要なエラーログを出さない。

## 対象外

- 既存 import 対象（`github_repository` / `github_branch_default` / `github_actions_repository_permissions` / ruleset）のロジック変更
- エラーメッセージの全面抑制（他の想定外エラーは従来通りログに残す）
- legacy `github_branch_protection` を残しているリポジトリの ruleset 移行

## 実装方針

`Terraform Import (core resources)` step 内で、`${WORKDIR}/main.tf` に `disable_default_main_protection = true` が含まれる場合のみ branch_protection の import をスキップする。

### 判定方法

`grep -Eq 'disable_default_main_protection[[:space:]]*=[[:space:]]*true' "${WORKDIR}/main.tf"` で判定。

- 対象ファイルは各リポジトリの `main.tf` 固定（現在の repository 別構造に合わせる）
- 正規表現は `=` 前後の空白を許容
- 該当時: `echo` でスキップ理由をログに残し、terraform import を実行しない
- 非該当時: 従来通り `terraform import ... || true` を実行

### 変更差分（抜粋）

```yaml
- name: Terraform Import (core resources)
  env:
    TF_VAR_github_token: ${{ steps.app_token.outputs.token }}
  run: |
    terraform -chdir="${WORKDIR}" import "module.this.github_repository.this[0]" "${REPO}" || true
    terraform -chdir="${WORKDIR}" import "module.this.github_branch_default.this" "${REPO}" || true
    terraform -chdir="${WORKDIR}" import "module.this.github_actions_repository_permissions.this[0]" "${REPO}" || true
    if grep -Eq 'disable_default_main_protection[[:space:]]*=[[:space:]]*true' "${WORKDIR}/main.tf"; then
      echo "Skip github_branch_protection import: ruleset-managed repo (disable_default_main_protection=true)"
    else
      terraform -chdir="${WORKDIR}" import 'module.this.github_branch_protection.this["main"]' "${REPO}:main" || true
    fi
```

## 変更ファイル

- `.github/workflows/terraform-import.yml` — 該当 step のみ書き換え

## テスト計画

1. `yamllint`（リポジトリ設定の `.yamllint`）と `actionlint`（pre-commit）が通ること
2. ruleset 管理リポジトリ (`claude-code-remote`) で workflow_dispatch → ログに "Skip github_branch_protection import" が出ること、`Configuration for import target does not exist` が出ないこと
3. legacy `github_branch_protection` を使うリポジトリ（`disable_default_main_protection` 指定なし、例: `blog`）で workflow_dispatch → 従来通り branch_protection が import 試行されること

## 懸念・留意点

- `main.tf` 以外のファイル（例: 将来的に `repository.tf` へ分割）に `disable_default_main_protection` が書かれるケースは未対応。現時点の全リポジトリは `main.tf` に集約されているため問題ない
- コメント行 (`# disable_default_main_protection = true`) にもマッチしてしまうが、プロジェクトの運用上そのようなコメントはなく、誤検知時の被害も「import をスキップしてログノイズ削減」に留まるため許容
