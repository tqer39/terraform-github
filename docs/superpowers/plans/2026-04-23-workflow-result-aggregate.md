# workflow-result への lint 集約 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `lint.yml` を `terraform-github.yml` に統合し、`workflow-result` が lint と terraform の完了を一括検査する状態にする。

**Architecture:** 既存の `lint.yml` のステップを `terraform-github.yml` の新規 `lint` ジョブに移植し、`workflow-result.needs` と検査ロジックに `lint` を追加する。重複実行を防ぐため旧 `lint.yml` を削除する。

**Tech Stack:** GitHub Actions, lefthook, just, Terraform

---

## Task 1: `terraform-github.yml` 統合 & `lint.yml` 削除

**Files:**

- Modify: `.github/workflows/terraform-github.yml`
- Delete: `.github/workflows/lint.yml`

- [ ] **Step 1: `terraform-github.yml` に `lint` ジョブを追加**

`.github/workflows/terraform-github.yml` の `jobs:` 直下、`set-matrix:` の前に以下を追加する（`set-matrix` は 20 行目から）:

```yaml
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
        with:
          ref: ${{ github.head_ref }}

      - name: Setup mise
        uses: jdx/mise-action@1648a7812b9aeae629881980618f079932869151 # v4
        with:
          install: true

      - name: Setup pnpm
        uses: pnpm/action-setup@fc06bc1257f339d1d5d8b3a19a8cae5388b55320 # v5
        with:
          run_install: false

      - name: Install node dependencies
        run: pnpm install --frozen-lockfile

      - name: Install betterleaks
        env:
          BETTERLEAKS_VERSION: 1.1.2
        run: |
          set -euo pipefail
          curl -fsSL "https://github.com/betterleaks/betterleaks/releases/download/v${BETTERLEAKS_VERSION}/betterleaks_${BETTERLEAKS_VERSION}_linux_x64.tar.gz" -o /tmp/betterleaks.tar.gz
          tar -xzf /tmp/betterleaks.tar.gz -C /tmp betterleaks
          sudo install -m 0755 /tmp/betterleaks /usr/local/bin/betterleaks
          betterleaks version

      - name: Run lefthook
        run: lefthook run pre-commit --all-files
```

- [ ] **Step 2: `workflow-result` ジョブの `needs` と検査ロジックを拡張**

`.github/workflows/terraform-github.yml` の `workflow-result:` ブロック（94-109 行付近）を以下に置き換える:

```yaml
  workflow-result:
    needs: [lint, set-matrix, terraform, delete-nochange-comments]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Check workflow result
        run: |
          if [ "${{ needs.lint.result }}" == "failure" ]; then
            echo "Lint failed"
            exit 1
          fi
          if [ "${{ needs.set-matrix.outputs.matrix }}" == '["_empty"]' ]; then
            echo "No repositories to process"
            exit 0
          fi
          if [ "${{ needs.terraform.result }}" == "failure" ]; then
            echo "Terraform jobs failed"
            exit 1
          fi
          echo "All jobs completed successfully"
```

- [ ] **Step 3: `lint.yml` を削除**

```bash
rm .github/workflows/lint.yml
```

- [ ] **Step 4: YAML/actionlint を lefthook で検証**

```bash
lefthook run pre-commit --files .github/workflows/terraform-github.yml
```

期待: `actionlint` と `yamllint` が green。失敗時はエラー内容に従い修正する。

- [ ] **Step 5: `just validate` を実行**

```bash
just validate
```

期待: Terraform 側に影響なく成功する（このタスクは Terraform ファイルを変更しないが、プロジェクト規約に従い確認する）。

- [ ] **Step 6: 差分確認**

```bash
git status
git diff .github/workflows/terraform-github.yml
```

期待:

- `.github/workflows/lint.yml` が削除リストに表示
- `terraform-github.yml` に `lint` ジョブ追加と `workflow-result` の差分

- [ ] **Step 7: コミット**

```bash
git add .github/workflows/terraform-github.yml .github/workflows/lint.yml
git commit -m "🔧 lint ジョブを terraform-github.yml に統合し workflow-result で集約"
```

コミットメッセージ本文（HEREDOC で作成済みの場合）:

```text
🔧 lint ジョブを terraform-github.yml に統合し workflow-result で集約

lint.yml を削除し、terraform-github.yml に lint ジョブを追加。
workflow-result の needs と検査ロジックに lint を含めることで、
PR status check を workflow-result 単一に集約する構造を完全にする。
```
