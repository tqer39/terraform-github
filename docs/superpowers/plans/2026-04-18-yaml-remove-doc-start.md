# YAML document-start marker 除去 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** リポジトリ内すべての YAML から先頭 `---` を除去し、yamllint の `document-start` ルールで再導入を禁止する。

**Architecture:** 2 コミット構成。Commit 1 で 15 ファイルの先頭 `---\n` を削除 (既存 lint を通過させる)。Commit 2 で `.yamllint` のルールを `disable` から `present: false, level: error` に強化し、pre-commit で再発を防ぐ。

**Tech Stack:** yamllint 1.38 / prek (pre-commit 互換) / Prettier / git / Edit ツール

**Spec:** `docs/superpowers/specs/2026-04-18-yaml-remove-doc-start-design.md`

**Working directory:** worktree `terraform-github-refactor/yaml-remove-doc-start` (branch: `refactor/yaml-remove-doc-start`)

---

## Task 1: すべての YAML から先頭 `---` を除去

**Files:**

- Modify: `.github/workflows/auto-assign.yml:1`
- Modify: `.github/workflows/generate-pr-description.yml:1`
- Modify: `.github/workflows/labeler.yml:1`
- Modify: `.github/workflows/prek.yml:1`
- Modify: `.github/workflows/terraform-github.yml:1`
- Modify: `.github/workflows/terraform-renovate.yml:1`
- Modify: `.github/workflows/update-license-year.yml:1`
- Modify: `.github/actions/set-matrix/action.yml:1`
- Modify: `.github/actions/terraform-apply/action.yml:1`
- Modify: `.github/actions/terraform-plan/action.yml:1`
- Modify: `.github/actions/terraform-validate/action.yml:1`
- Modify: `.github/labeler.yml:1`
- Modify: `.github/auto_assign.yml:1`
- Modify: `.pre-commit-config.yaml:1`
- Modify: `.yamllint:1`

- [ ] **Step 1: 事前確認 — 対象 15 ファイルを特定**

Run:

```bash
git ls-files '*.yml' '*.yaml' '.yamllint' \
  | xargs -I{} sh -c 'head -1 "{}" | grep -q "^---$" && echo "{}"'
```

Expected output (順不同、15 行):

```text
.github/actions/set-matrix/action.yml
.github/actions/terraform-apply/action.yml
.github/actions/terraform-plan/action.yml
.github/actions/terraform-validate/action.yml
.github/auto_assign.yml
.github/labeler.yml
.github/workflows/auto-assign.yml
.github/workflows/generate-pr-description.yml
.github/workflows/labeler.yml
.github/workflows/prek.yml
.github/workflows/terraform-github.yml
.github/workflows/terraform-renovate.yml
.github/workflows/update-license-year.yml
.pre-commit-config.yaml
.yamllint
```

- [ ] **Step 2: 多文書 YAML が無いことを確認**

Run:

```bash
git ls-files '*.yml' '*.yaml' '.yamllint' \
  | xargs -I{} sh -c 'c=$(grep -c "^---$" "{}"); [ "$c" -gt 1 ] && echo "{}: $c"'
```

Expected output: 空 (多文書 YAML ゼロ)

- [ ] **Step 3: 15 ファイルから先頭 `---\n` を削除**

各ファイルについて、先頭行 `---` と直後の改行を削除する。`Edit` ツールで `old_string` に以下の先頭 2 行を設定し、`new_string` には 1 行目以降 (= `---` を除いた後続行) を残すようにする。

例: `.github/workflows/auto-assign.yml`

現状:

```yaml
---
name: Auto Assign

on:
  pull_request:
```

Edit:

- old_string (最初の 2 行を一意にするために 3 行分含める):

  ```yaml
  ---
  name: Auto Assign

  ```

- new_string:

  ```yaml
  name: Auto Assign

  ```

同様のパターンで 15 ファイルすべてに適用する。`Edit` は先頭行が `---` で後続行との組み合わせで一意に特定できるので安全。

一括処理したい場合の参考コマンド (手動実行で代替する場合):

```bash
for f in $(git ls-files '*.yml' '*.yaml' '.yamllint' \
    | xargs -I{} sh -c 'head -1 "{}" | grep -q "^---$" && echo "{}"'); do
  # 先頭が --- のみの行を削除 (macOS の sed)
  sed -i '' '1{/^---$/d;}' "$f"
done
```

**どちらの方法でも可。`Edit` 推奨 (差分が明示的)。**

- [ ] **Step 4: 除去後の残存ゼロを確認**

Run:

```bash
git ls-files '*.yml' '*.yaml' '.yamllint' \
  | xargs -I{} sh -c 'head -1 "{}" | grep -q "^---$" && echo "{}"'
```

Expected output: 空

追加で行数を確認:

```bash
git ls-files '*.yml' '*.yaml' '.yamllint' \
  | xargs grep -l "^---$" 2>/dev/null || true
```

Expected output: 空

- [ ] **Step 5: 各ファイルの先頭が正しいかサンプリング確認**

Run:

```bash
for f in .github/workflows/auto-assign.yml \
         .github/actions/set-matrix/action.yml \
         .pre-commit-config.yaml \
         .yamllint; do
  echo "=== $f ==="
  head -2 "$f"
done
```

Expected: 各ファイルの 1 行目が `name:` / コメント / 他の有効 YAML キーで始まる (`---` が存在しない)

- [ ] **Step 6: pre-commit フックを全ファイルに対して実行**

Run:

```bash
prek run --all-files
```

Expected: すべての hook が Passed または Skipped。Failed なし。特に `yamllint` / `check-yaml` / `actionlint-docker` / `Format GitHub Actions workflow files` (prettier) が緑。

※ `prek` が見つからない場合は `pre-commit run --all-files` で代替。

- [ ] **Step 7: git diff の確認**

Run:

```bash
git diff --stat
git diff -- .yamllint | head -20
```

Expected: 15 ファイルが変更され、各ファイルで `-` のみ (先頭 `---` 1 行の削除) が発生。追加行なし。

- [ ] **Step 8: Commit 1**

Run:

```bash
git add -- \
  .github/workflows/auto-assign.yml \
  .github/workflows/generate-pr-description.yml \
  .github/workflows/labeler.yml \
  .github/workflows/prek.yml \
  .github/workflows/terraform-github.yml \
  .github/workflows/terraform-renovate.yml \
  .github/workflows/update-license-year.yml \
  .github/actions/set-matrix/action.yml \
  .github/actions/terraform-apply/action.yml \
  .github/actions/terraform-plan/action.yml \
  .github/actions/terraform-validate/action.yml \
  .github/labeler.yml \
  .github/auto_assign.yml \
  .pre-commit-config.yaml \
  .yamllint

git commit -m "refactor: remove YAML document-start marker from all configs"
```

Expected: コミット成功。pre-commit フックがすべて Passed。

---

## Task 2: yamllint で document-start を禁止

**Files:**

- Modify: `.yamllint:36` (`document-start: disable` を `present: false, level: error` に変更)

- [ ] **Step 1: 変更前の状態を確認**

Run:

```bash
sed -n '30,45p' .yamllint
```

Expected output (抜粋):

```yaml
  # Disabled - not needed for this project
  document-end: disable
  document-start: disable
  empty-values: disable
  ...
```

- [ ] **Step 2: `.yamllint` の `document-start` ルールを変更**

Use `Edit` tool:

- file: `.yamllint`
- old_string:

  ```yaml
    document-end: disable
    document-start: disable
    empty-values: disable
  ```

- new_string:

  ```yaml
    document-end: disable
    document-start:
      present: false
      level: error
    empty-values: disable
  ```

- [ ] **Step 3: 変更後の構造を確認**

Run:

```bash
sed -n '30,48p' .yamllint
```

Expected output (抜粋):

```yaml
  # Disabled - not needed for this project
  document-end: disable
  document-start:
    present: false
    level: error
  empty-values: disable
  ...
```

- [ ] **Step 4: yamllint が全ファイルで緑になることを確認**

Run:

```bash
prek run yamllint --all-files
```

Expected: Passed (全 YAML に `---` が無いのでエラーなし)

- [ ] **Step 5: 逆テスト — 任意ファイルに `---` を挿入して error で失敗することを確認**

Run:

```bash
# 一時的に auto-merge.yml の先頭に --- を付与
printf '%s\n%s\n' '---' "$(cat .github/workflows/auto-merge.yml)" \
  > /tmp/auto-merge-with-doc-start.yml

# yamllint の直接呼び出しで error になることを確認
docker run --rm -v "$(pwd)":/src -w /src python:3.12-slim \
  sh -c 'pip install yamllint==1.38.0 -q && \
    yamllint -c .yamllint /tmp/auto-merge-with-doc-start.yml' \
  2>&1 || true
```

※ Docker が無い環境の場合は、以下の代替で確認:

```bash
# 実ファイルを一時変更 (戻すことを忘れずに)
cp .github/workflows/auto-merge.yml /tmp/auto-merge.yml.bak
printf '%s\n%s' '---' "$(cat .github/workflows/auto-merge.yml)" \
  > .github/workflows/auto-merge.yml

prek run yamllint --files .github/workflows/auto-merge.yml 2>&1 | tail -5
# → yamllint が `found forbidden document start "---"` 等の error を出して Failed になる

# 必ず戻す
cp /tmp/auto-merge.yml.bak .github/workflows/auto-merge.yml
rm /tmp/auto-merge.yml.bak

# 戻ったことを確認
prek run yamllint --files .github/workflows/auto-merge.yml
# → Passed
```

Expected: `---` を挿入した状態では yamllint が `error` で Failed。元に戻したら Passed。

- [ ] **Step 6: 全ファイルでもう一度 pre-commit を回す (最終確認)**

Run:

```bash
prek run --all-files
```

Expected: すべて Passed / Skipped。Failed なし。

- [ ] **Step 7: git diff の確認**

Run:

```bash
git diff -- .yamllint
```

Expected output:

```diff
-  document-start: disable
+  document-start:
+    present: false
+    level: error
```

変更は `.yamllint` 1 ファイルのみ。

- [ ] **Step 8: Commit 2**

Run:

```bash
git add .yamllint
git commit -m "chore(yamllint): forbid YAML document-start marker"
```

Expected: コミット成功。pre-commit フックがすべて Passed。

---

## Task 3: 最終検証

**Files:** (変更なし、検証のみ)

- [ ] **Step 1: ブランチの状態を確認**

Run:

```bash
git log --oneline main..HEAD
```

Expected output (2 コミット):

```text
<sha2> chore(yamllint): forbid YAML document-start marker
<sha1> refactor: remove YAML document-start marker from all configs
```

- [ ] **Step 2: 残存 `---` がないことを最終確認**

Run:

```bash
git grep -n "^---$" -- '*.yml' '*.yaml' '.yamllint' || echo "no matches"
```

Expected output: `no matches`

- [ ] **Step 3: pre-commit フルラン**

Run:

```bash
prek run --all-files
```

Expected: すべて Passed / Skipped。Failed なし。

- [ ] **Step 4: Terraform validate (無関係だが念のため)**

Run:

```bash
just validate
```

Expected: green (今回の変更は YAML のみのため影響なし)

※ `just validate` が重い場合、`just` が使えない場合はスキップ可。その場合はこのステップを省略してよい。

- [ ] **Step 5: PR 作成準備**

Run:

```bash
git push -u origin refactor/yaml-remove-doc-start
```

※ PR 作成自体は本計画の対象外。ユーザーの指示に従う。

---

## 自己レビュー

**Spec coverage:**

- Spec「Commit 1: `---` 除去 (15 ファイル)」 → Task 1
- Spec「Commit 2: yamllint ルール強化」 → Task 2
- Spec「検証」セクション → Task 3 + 各 Task の最終ステップ
- Spec「逆テスト」→ Task 2 Step 5

**Placeholder scan:** TBD / TODO / 「後で実装」なし。全ステップにコマンドまたは具体的な編集内容あり。

**Type consistency:** ファイル名・ブランチ名・コミットメッセージはすべて一致。
