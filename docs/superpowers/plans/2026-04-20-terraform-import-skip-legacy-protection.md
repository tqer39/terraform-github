# terraform-import: ruleset 管理リポジトリでの legacy branch_protection import スキップ 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `.github/workflows/terraform-import.yml` の core resources import step で、`disable_default_main_protection = true` のリポジトリでは `github_branch_protection.this["main"]` の import をスキップし、`Configuration for import target does not exist` エラーのログノイズを解消する。

**Architecture:** 単一ファイル (`.github/workflows/terraform-import.yml`) の 1 step を書き換えるだけ。`grep -Eq` による `main.tf` 内フラグ判定で分岐。

**Tech Stack:** GitHub Actions YAML, Bash, grep, Terraform

**Spec:** `docs/superpowers/specs/2026-04-20-terraform-import-skip-legacy-protection-design.md`

---

## File Structure

- Modify: `.github/workflows/terraform-import.yml` (lines 55-62 付近の `Terraform Import (core resources)` step)

他ファイル変更なし。テストは lint (actionlint / yamllint) と、実リポジトリでの workflow_dispatch 実行で行う。自動テストフレームワークは無い。

---

### Task 1: core resources import step を条件分岐対応に書き換える

**Files:**

- Modify: `.github/workflows/terraform-import.yml:55-62`

- [ ] **Step 1: 現在の step を確認**

Run: `sed -n '55,62p' .github/workflows/terraform-import.yml`

Expected output:

```yaml
      - name: Terraform Import (core resources)
        env:
          TF_VAR_github_token: ${{ steps.app_token.outputs.token }}
        run: |
          terraform -chdir="${WORKDIR}" import "module.this.github_repository.this[0]" "${REPO}" || true
          terraform -chdir="${WORKDIR}" import "module.this.github_branch_default.this" "${REPO}" || true
          terraform -chdir="${WORKDIR}" import "module.this.github_actions_repository_permissions.this[0]" "${REPO}" || true
          terraform -chdir="${WORKDIR}" import 'module.this.github_branch_protection.this["main"]' "${REPO}:main" || true
```

- [ ] **Step 2: step の `run:` ブロックを書き換える**

Edit `.github/workflows/terraform-import.yml` の該当箇所を以下に置き換える:

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

- [ ] **Step 3: 変更を確認**

Run: `sed -n '55,66p' .github/workflows/terraform-import.yml`

Expected: 新しい if/else ブロックが含まれていること。

- [ ] **Step 4: yamllint で構文検証**

Run: `pnpm exec yamllint .github/workflows/terraform-import.yml`

Expected: エラーなし（既存 workflow と同じ指摘レベル以下）。yamllint 未インストール時は `pnpm install` を先に実行。

- [ ] **Step 5: actionlint で workflow 検証**

Run: `pre-commit run actionlint --files .github/workflows/terraform-import.yml || lefthook run pre-commit --files .github/workflows/terraform-import.yml`

または直接:

Run: `actionlint .github/workflows/terraform-import.yml`

Expected: エラーなし。actionlint 未インストール時は `brew install actionlint`。

- [ ] **Step 6: 判定ロジックを手元でドライラン検証**

Run (ruleset-managed case):

```bash
WORKDIR=./terraform/src/repositories/claude-code-remote
if grep -Eq 'disable_default_main_protection[[:space:]]*=[[:space:]]*true' "${WORKDIR}/main.tf"; then
  echo "SKIP"
else
  echo "RUN"
fi
```

Expected: `SKIP`

Run (legacy-managed case):

```bash
WORKDIR=./terraform/src/repositories/blog
if grep -Eq 'disable_default_main_protection[[:space:]]*=[[:space:]]*true' "${WORKDIR}/main.tf"; then
  echo "SKIP"
else
  echo "RUN"
fi
```

Expected: `RUN`

（`blog` が存在しない/ `disable_default_main_protection` を含まない場合は `RUN`。存在しないファイルなら grep 自体が失敗し else 側に入る — これは手元検証のみで本番 workflow では `Verify workdir exists` step が既に存在確認済み）

- [ ] **Step 7: コミット**

```bash
git add .github/workflows/terraform-import.yml
git commit -m "$(cat <<'EOF'
🔧 terraform-import: ruleset 管理リポジトリで legacy branch_protection import をスキップ

disable_default_main_protection = true のリポジトリでは
github_branch_protection リソースが生成されないため、無条件 import で
"Configuration for import target does not exist" エラーがログに出ていた。
main.tf を grep してフラグを検知し、該当時は import をスキップする。

Refs: docs/superpowers/specs/2026-04-20-terraform-import-skip-legacy-protection-design.md
EOF
)"
```

Expected: pre-commit hook（cspell, textlint, markdownlint, actionlint, yamllint 等）が全て pass してコミット成功。

---

### Task 2: PR を作成して本番検証

**Files:** なし（GitHub 操作のみ）

- [ ] **Step 1: ブランチを push して PR 作成**

現在のブランチ (`streamed-floating-steele` ベースの worktree) から:

```bash
git push -u origin HEAD
gh pr create --title "🔧 terraform-import: ruleset 管理リポジトリで legacy branch_protection import をスキップ" --body "$(cat <<'EOF'
## Summary
- run 24635657942 で `claude-code-remote` の import 時に `Configuration for import target does not exist` エラーが出ていた
- `disable_default_main_protection = true` のリポジトリでは module 側で `github_branch_protection` が生成されないため、無条件 import が失敗する
- `main.tf` を grep してフラグを検知し、該当時はスキップする

## Test plan
- [ ] actionlint / yamllint が pass
- [ ] PR マージ後、`claude-code-remote` に対して workflow_dispatch を実行
- [ ] ログに "Skip github_branch_protection import" が出て、`Configuration for import target does not exist` が出ないことを確認
- [ ] `blog` など legacy protection リポジトリで workflow_dispatch し、従来通り branch_protection が import 試行されることを確認

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Refs: docs/superpowers/specs/2026-04-20-terraform-import-skip-legacy-protection-design.md
EOF
)"
```

Expected: PR URL が表示される。

- [ ] **Step 2: CI の完了待ち**

Run: `gh pr checks --watch`

Expected: 全 check が pass。

- [ ] **Step 3: マージ**

ユーザー承認を得てから:

```bash
gh pr merge --auto --squash
```

または claude-auto ラベルによる auto-merge を待機。

- [ ] **Step 4: マージ後の動作確認（ruleset 管理リポジトリ）**

main ブランチに反映後:

```bash
gh workflow run terraform-import.yml -f repo=claude-code-remote
```

数秒待って最新 run を取得:

```bash
gh run list --workflow=terraform-import.yml --limit=1 --json databaseId,conclusion,status
```

完了したら:

```bash
RUN_ID=$(gh run list --workflow=terraform-import.yml --limit=1 --json databaseId --jq '.[0].databaseId')
gh run view "$RUN_ID" --log 2>&1 | grep -E "Skip github_branch_protection|Configuration for import target"
```

Expected:

- `Skip github_branch_protection import: ruleset-managed repo (disable_default_main_protection=true)` が出る
- `Configuration for import target does not exist` は出ない

- [ ] **Step 5: マージ後の動作確認（legacy 管理リポジトリ、該当があれば）**

`disable_default_main_protection` を指定していないリポジトリが残っていればそれを選び、同様に workflow_dispatch してログで `module.this.github_branch_protection.this["main"]: Importing from ID` が表示されることを確認する。

該当リポジトリが無い場合は Step 5 をスキップ（この場合 step 2 の機能回帰確認は grep ロジックのドライランのみで担保）。

候補調査:

```bash
grep -L 'disable_default_main_protection *= *true' terraform/src/repositories/*/main.tf
```

Expected: `disable_default_main_protection = true` を含まない main.tf のリストが出る。

---

## Self-Review

**1. Spec coverage:**

- ログエラーの原因特定 → Task 1 Step 2 で if/else により修正
- ruleset 管理リポジトリで import スキップ → Step 6 でドライラン検証, Step 4 本番検証
- legacy リポジトリで従来通り動作 → Step 6 ドライラン, Step 5 本番検証
- ファイル変更: `.github/workflows/terraform-import.yml` のみ → File Structure 明記
- テスト計画: yamllint / actionlint / 実 workflow_dispatch → Steps 4/5 (lint), Task 2 Steps 4-5 (実行)

**2. Placeholder scan:** TBD / TODO / "implement later" なし。全 step に実行コマンドと期待出力を記載。

**3. Type consistency:** 単一 bash スクリプト内で完結。`WORKDIR` / `REPO` 変数名は既存 workflow と同じ。正規表現 `disable_default_main_protection[[:space:]]*=[[:space:]]*true` は Task 1 Step 2 と Step 6 で一貫。

---

## 実行方式の選択

この計画を実行するには:

1. **Subagent-Driven (推奨)** - タスク毎に fresh subagent 起動
2. **Inline Execution** - このセッション内で executing-plans を使い実行

Task 数が 2 個と小さいため、inline execution でも十分。
