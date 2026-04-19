# terraform-import ワークフロー修正 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `terraform-import` ワークフローをリポジトリ別ステート構造に対応させ、失敗を解消する。

**Architecture:** `workflow_dispatch` で `repo` を受け取り、`terraform/src/repositories/${repo}/` 配下で `module.this.*` 配下のリソースを import する。認証・トークン取得は既存の `terraform-github.yml` と揃える。Ruleset は `gh api` で動的 ID 取得。

**Tech Stack:** GitHub Actions, Terraform, GitHub CLI (`gh`), AWS OIDC, GitHub App

**Spec:** `docs/superpowers/specs/2026-04-20-terraform-import-workflow-fix-design.md`

---

## File Structure

- **Modify:** `.github/workflows/terraform-import.yml` — 全面書き換え

これは単一ファイル変更の小規模タスク。TDD の対象は「ワークフロー実行結果」となるため、実装は段階的に書き換え、最後に GitHub Actions 上で動作確認する。

---

### Task 1: 入力仕様と認証ステップを修正

**Files:**

- Modify: `.github/workflows/terraform-import.yml` (全面)

- [ ] **Step 1: 現状のファイルを確認**

Run: `cat .github/workflows/terraform-import.yml`
Expected: 現行の壊れたワークフロー内容が表示される

- [ ] **Step 2: ワークフロー全体を書き換え**

以下の内容で `.github/workflows/terraform-import.yml` を上書き:

```yaml
name: Terraform Import

on:
  workflow_dispatch:
    inputs:
      repo:
        description: 'GitHub repository name (例: blog)。terraform/src/repositories/<repo>/ が存在すること'
        required: true
        type: string

jobs:
  terraform-import:
    timeout-minutes: 10
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    env:
      REPO: ${{ github.event.inputs.repo }}
      WORKDIR: ./terraform/src/repositories/${{ github.event.inputs.repo }}

    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6

      - name: AWS Credential
        uses: ./.github/actions/aws-credential
        with:
          oidc-iam-role: arn:aws:iam::072693953877:role/portfolio-terraform-github-deploy

      - name: Generate GitHub App Token
        id: app_token
        uses: actions/create-github-app-token@1b10c78c7865c340bc4f6099eb2f838309f1e8c3 # v3
        with:
          app-id: ${{ secrets.GHA_APP_ID }}
          private-key: ${{ secrets.GHA_APP_PRIVATE_KEY }}
          owner: ${{ github.repository_owner }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@5e8dbf3c6d9deaf4193ca7a8fb23f2ac83bb6c85 # v4

      - name: Verify workdir exists
        run: |
          if [ ! -d "${WORKDIR}" ]; then
            echo "::error::Directory not found: ${WORKDIR}"
            echo "Create terraform/src/repositories/${REPO}/main.tf first."
            exit 1
          fi

      - name: Terraform Init
        run: terraform -chdir="${WORKDIR}" init -reconfigure

      - name: Terraform Import (core resources)
        env:
          TF_VAR_github_token: ${{ steps.app_token.outputs.token }}
        run: |
          terraform -chdir="${WORKDIR}" import "module.this.github_repository.this[0]" "${REPO}" || true
          terraform -chdir="${WORKDIR}" import "module.this.github_branch_default.this" "${REPO}" || true
          terraform -chdir="${WORKDIR}" import "module.this.github_actions_repository_permissions.this[0]" "${REPO}" || true
          terraform -chdir="${WORKDIR}" import 'module.this.github_branch_protection.this["main"]' "${REPO}:main" || true

      - name: Terraform Import (rulesets)
        env:
          TF_VAR_github_token: ${{ steps.app_token.outputs.token }}
          GH_TOKEN: ${{ steps.app_token.outputs.token }}
        run: |
          set -euo pipefail
          ruleset_json=$(gh api "repos/tqer39/${REPO}/rulesets" 2>/dev/null || echo "[]")
          echo "${ruleset_json}" | jq -c '.[]' | while read -r rs; do
            id=$(echo "${rs}" | jq -r '.id')
            name=$(echo "${rs}" | jq -r '.name')
            echo "Importing ruleset id=${id} name=${name}"
            terraform -chdir="${WORKDIR}" import "module.this.github_repository_ruleset.default_main_protection[0]" "${REPO}:${id}" || true
            terraform -chdir="${WORKDIR}" import "module.this.github_repository_ruleset.this[\"${name}\"]" "${REPO}:${id}" || true
          done
```

- [ ] **Step 3: yamllint で検証**

Run: `pnpm exec yamllint .github/workflows/terraform-import.yml`
Expected: エラーなし（または既存ワークフローと同水準の warning のみ）

- [ ] **Step 4: actionlint で検証**

Run: `actionlint .github/workflows/terraform-import.yml 2>&1 || true`
Expected: エラーなし。`actionlint` 未インストールなら `pnpm exec actionlint` または skip

- [ ] **Step 5: diff 確認**

Run: `git diff .github/workflows/terraform-import.yml`
Expected: 変更内容が想定通り

- [ ] **Step 6: コミット**

```bash
git add .github/workflows/terraform-import.yml
git commit -m "🔧 terraform-import ワークフローをリポジトリ別ステート構造に対応"
```

---

### Task 2: GitHub 上でワークフローの動作確認

**Files:**

- なし (ワークフロー実行のみ)

**Prerequisite:** Task 1 がマージされている、もしくは当該ブランチ上で workflow_dispatch を実行できる状態。

- [ ] **Step 1: PR を作成 (未作成の場合)**

Run:

```bash
git push -u origin HEAD
gh pr create --fill --label claude-auto
```

Expected: PR が作成される

- [ ] **Step 2: PR 上でワークフロー存在確認**

Run: `gh workflow list --all | grep 'Terraform Import'`
Expected: `Terraform Import` が一覧にある

- [ ] **Step 3: PR のブランチ上で既存リポジトリ `blog` を指定して手動実行**

Run:

```bash
gh workflow run terraform-import.yml --ref "$(git branch --show-current)" -f repo=blog
```

Expected: "Created workflow_dispatch event" のようなメッセージ

- [ ] **Step 4: 実行結果を確認**

Run:

```bash
sleep 10
gh run list --workflow=terraform-import.yml --limit 1
gh run view --log 2>&1 | tail -80
```

Expected: Verify workdir / Init / Import core / Import rulesets の全ステップが success (exit 0)

- [ ] **Step 5: state 差分が出ないことを確認 (blog ディレクトリで plan)**

このステップは CI 側の通常 plan で自動確認される。手元で確認したい場合:
Run:

```bash
gh run list --workflow=terraform-github.yml --limit 5
```

Expected: 直近の blog 対象の plan に差分がない (import 結果が反映されていれば "No changes" になる)

- [ ] **Step 6: 実行ログを PR にコメント (任意)**

Run:

```bash
gh pr comment --body "terraform-import ワークフロー手動実行: [run link](https://github.com/tqer39/terraform-github/actions/runs/<RUN_ID>)"
```

Expected: PR にコメント追加

---

## Notes for Executor

- **認証前提**: `portfolio-terraform-github-deploy` OIDC ロール、`GHA_APP_ID` / `GHA_APP_PRIVATE_KEY` シークレットが既存。`terraform-github.yml` と同じ認証パスなので新規設定は不要。
- **冪等性**: 全 import に `|| true` が付いている。既に state にある / リソースが存在しない場合は skip。
- **ruleset import の挙動**: 2 つのアドレス (`default_main_protection[0]` と `this[<name>]`) に対して両方試行する。実際に state 上に存在するのはどちらか片方だけなので、他方は `|| true` で握りつぶされる。
- **jq/gh の availability**: GitHub-hosted runner には jq・gh が標準搭載されている。追加 setup 不要。
- **テスト不可領域**: ワークフロー変更は local で完全に再現できないため、Task 2 で CI 上での動作確認を必須とする。ここで失敗した場合は Task 1 に戻って修正すること。
