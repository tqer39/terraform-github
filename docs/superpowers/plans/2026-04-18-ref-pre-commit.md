<!-- markdownlint-disable MD040 MD060 -->
<!-- cSpell:ignore lefthook yamllint actionlint shellcheck markdownlint textlint cspell biomejs dlx frozen jdx renovatebot AKIA ASIA tfsec takeruooyama pipefail esac mktemp -->

# ref-pre-commit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `.pre-commit-config.yaml` + prek から `lefthook.yml` + mise/pnpm 管理へ移行し、不要フック 2 件削除・バグ 1 件修正・Docker 依存 1 件解消する。

**Architecture:** 依存宣言 (`.tool-versions` + `package.json`) と実行計画 (`lefthook.yml`) を分離。セーフティ系フックは `scripts/lint/*.sh` の薄い自作スクリプトで担う。

**Tech Stack:** lefthook (Go), mise, pnpm, yamllint, actionlint, shellcheck, terraform, cspell, markdownlint-cli2, textlint, biome

**Spec:** `docs/superpowers/specs/2026-04-18-ref-pre-commit-design.md`

---

## ファイル構成マップ

### 新規作成

- `package.json` — Node ツールバージョン宣言
- `pnpm-lock.yaml` — ロックファイル (pnpm が生成)
- `lefthook.yml` — 実行計画
- `scripts/lint/check-added-large-files.sh` — 大容量ファイル検出
- `scripts/lint/check-json.sh` — JSON 構文検査
- `scripts/lint/detect-aws-credentials.sh` — AWS 認証情報検出
- `scripts/lint/detect-private-key.sh` — 秘密鍵検出
- `scripts/lint/end-of-file-fixer.sh` — 末尾改行保証
- `scripts/lint/mixed-line-ending.sh` — LF 統一
- `scripts/lint/trailing-whitespace.sh` — 行末空白除去
- `.github/workflows/lint.yml` — 新 CI workflow

### 変更

- `.tool-versions` — lefthook, yamllint, actionlint, shellcheck を追加
- `justfile` — `setup` / `lint` レシピを lefthook 化
- `scripts/check-tools.sh` — 新ツール群のチェックに更新
- `.gitignore` — `node_modules/` を追加 (未記載の場合)

### 削除

- `.pre-commit-config.yaml`
- `.github/workflows/prek.yml`

---

## Task 1: Node ツール依存宣言 (`package.json` + `pnpm-lock.yaml`)

**Files:**

- Create: `package.json`
- Create: `pnpm-lock.yaml` (pnpm 生成)
- Modify: `.gitignore` (必要なら `node_modules/` 追記)

- [ ] **Step 1: `.gitignore` に `node_modules/` が無ければ追記**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
grep -qxF 'node_modules/' .gitignore || echo 'node_modules/' >> .gitignore
```

- [ ] **Step 2: `package.json` を作成**

`package.json`:

```json
{
  "name": "terraform-github-devtools",
  "private": true,
  "description": "Development tool dependencies for terraform-github (run via lefthook).",
  "packageManager": "pnpm@9.15.9",
  "devDependencies": {
    "@biomejs/biome": "1.9.4",
    "cspell": "9.8.0",
    "markdownlint-cli2": "0.22.0",
    "textlint": "15.5.4",
    "textlint-filter-rule-allowlist": "4.0.0",
    "textlint-filter-rule-comments": "1.3.0",
    "textlint-rule-ja-no-space-between-full-width": "2.4.2",
    "textlint-rule-no-dropping-the-ra": "3.0.0",
    "textlint-rule-terminology": "5.2.16"
  }
}
```

> バージョン: spec の現行 pre-commit-config.yaml に書かれた値をそのまま固定。Renovate が追随する。

- [ ] **Step 3: `pnpm install` で lockfile 生成**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
pnpm install
```

Expected: `pnpm-lock.yaml` 生成、`node_modules/` 作成、`.gitignore` で無視されていること確認。

- [ ] **Step 4: Node ツール単体動作確認**

```bash
pnpm exec cspell --version
pnpm exec markdownlint-cli2 --version
pnpm exec textlint --version
pnpm exec biome --version
```

Expected: 各コマンドが package.json の固定バージョンを出力。

- [ ] **Step 5: コミット**

```bash
git add package.json pnpm-lock.yaml .gitignore
git commit -m "feat(pre-commit): add package.json for lefthook node tools"
```

---

## Task 2: CLI ツール依存宣言 (`.tool-versions`)

**Files:**

- Modify: `.tool-versions`

- [ ] **Step 1: 現行 `.tool-versions` を確認**

```bash
cat /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit/.tool-versions
```

- [ ] **Step 2: 4 ツールを追加**

`.tool-versions` に末尾追記 (既存行の重複回避):

```
lefthook 1.8.4
yamllint 1.38.0
actionlint 1.7.12
shellcheck 0.11.0
```

> バージョン: 各ツールの最新安定版 (実装時点)。Renovate の mise manager が追随。既に定義済みならスキップ。

- [ ] **Step 3: `mise install` で導入**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
mise install
```

- [ ] **Step 4: 各ツール動作確認**

```bash
lefthook version
yamllint --version
actionlint -version
shellcheck --version
```

Expected: 全コマンドが `.tool-versions` 固定バージョンを出力。

- [ ] **Step 5: コミット**

```bash
git add .tool-versions
git commit -m "feat(pre-commit): add lefthook/yamllint/actionlint/shellcheck to .tool-versions"
```

---

## Task 3: セーフティ系シェルスクリプト (7 本)

各スクリプトは pre-commit-hooks の対応フックと同等機能を持ち、引数で staged ファイルを受ける。`set -euo pipefail` で統一。

**Files:**

- Create: `scripts/lint/check-added-large-files.sh`
- Create: `scripts/lint/check-json.sh`
- Create: `scripts/lint/detect-aws-credentials.sh`
- Create: `scripts/lint/detect-private-key.sh`
- Create: `scripts/lint/end-of-file-fixer.sh`
- Create: `scripts/lint/mixed-line-ending.sh`
- Create: `scripts/lint/trailing-whitespace.sh`

- [ ] **Step 1: ディレクトリ作成**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
mkdir -p scripts/lint
```

- [ ] **Step 2: `check-added-large-files.sh` 作成**

`scripts/lint/check-added-large-files.sh`:

```bash
#!/usr/bin/env bash
# Fail if any staged file exceeds --max-kb (default 512).
set -euo pipefail

max_kb=512
files=()
for arg in "$@"; do
  case "$arg" in
    --max-kb=*) max_kb="${arg#--max-kb=}" ;;
    *) files+=("$arg") ;;
  esac
done

exit_code=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  size_bytes=$(wc -c <"$f")
  size_kb=$(( size_bytes / 1024 ))
  if (( size_kb > max_kb )); then
    printf '%s: %d KB (exceeds %d KB)\n' "$f" "$size_kb" "$max_kb" >&2
    exit_code=1
  fi
done
exit "$exit_code"
```

- [ ] **Step 3: `check-json.sh` 作成**

`scripts/lint/check-json.sh`:

```bash
#!/usr/bin/env bash
# Validate JSON syntax for each given file (ignores .json5).
set -euo pipefail

exit_code=0
for f in "$@"; do
  [[ -f "$f" ]] || continue
  [[ "$f" == *.json5 ]] && continue
  if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null; then
    printf '%s: invalid JSON\n' "$f" >&2
    exit_code=1
  fi
done
exit "$exit_code"
```

- [ ] **Step 4: `detect-aws-credentials.sh` 作成**

`scripts/lint/detect-aws-credentials.sh`:

```bash
#!/usr/bin/env bash
# Detect AWS Access Key IDs in staged files.
# --allow-missing-credentials: kept for compatibility; we do not read ~/.aws.
set -euo pipefail

files=()
for arg in "$@"; do
  case "$arg" in
    --allow-missing-credentials) ;;
    *) files+=("$arg") ;;
  esac
done

exit_code=0
pattern='(AKIA|ASIA)[0-9A-Z]{16}'
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  if grep -En "$pattern" "$f" >/dev/null 2>&1; then
    printf '%s: possible AWS Access Key ID\n' "$f" >&2
    grep -En "$pattern" "$f" >&2 || true
    exit_code=1
  fi
done
exit "$exit_code"
```

- [ ] **Step 5: `detect-private-key.sh` 作成**

`scripts/lint/detect-private-key.sh`:

```bash
#!/usr/bin/env bash
# Detect private key headers (PEM / OpenSSH).
set -euo pipefail

exit_code=0
pattern='-----BEGIN [A-Z ]*PRIVATE KEY-----'
for f in "$@"; do
  [[ -f "$f" ]] || continue
  if grep -En "$pattern" "$f" >/dev/null 2>&1; then
    printf '%s: private key detected\n' "$f" >&2
    exit_code=1
  fi
done
exit "$exit_code"
```

- [ ] **Step 6: `end-of-file-fixer.sh` 作成**

`scripts/lint/end-of-file-fixer.sh`:

```bash
#!/usr/bin/env bash
# Ensure each text file ends with exactly one newline. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  # Skip binary files (heuristic: grep -Iq returns 1 for binary).
  grep -Iq . "$f" || continue
  # Add newline if missing.
  if [[ -n "$(tail -c 1 "$f")" ]]; then
    printf '\n' >>"$f"
  fi
done
```

- [ ] **Step 7: `mixed-line-ending.sh` 作成**

`scripts/lint/mixed-line-ending.sh`:

```bash
#!/usr/bin/env bash
# Normalize line endings to LF. --fix=lf is required.
set -euo pipefail

mode=""
files=()
for arg in "$@"; do
  case "$arg" in
    --fix=*) mode="${arg#--fix=}" ;;
    *) files+=("$arg") ;;
  esac
done

if [[ "$mode" != "lf" ]]; then
  echo "mixed-line-ending.sh: only --fix=lf is supported" >&2
  exit 2
fi

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  # Strip CR in place.
  if grep -q $'\r' "$f"; then
    tr -d '\r' <"$f" >"$f.tmp" && mv "$f.tmp" "$f"
  fi
done
```

- [ ] **Step 8: `trailing-whitespace.sh` 作成**

`scripts/lint/trailing-whitespace.sh`:

```bash
#!/usr/bin/env bash
# Remove trailing whitespace from text files. Modifies in place.
set -euo pipefail

for f in "$@"; do
  [[ -f "$f" ]] || continue
  grep -Iq . "$f" || continue
  # sed -i is GNU syntax; use portable form.
  sed -E 's/[[:space:]]+$//' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
done
```

- [ ] **Step 9: 全スクリプトを実行可能にする**

```bash
chmod +x scripts/lint/*.sh
```

- [ ] **Step 10: フィクスチャで各スクリプトを手動検証**

違反/非違反サンプルで動作確認:

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
tmpdir=$(mktemp -d)

# check-added-large-files
dd if=/dev/zero of="$tmpdir/big.bin" bs=1024 count=1024 2>/dev/null
./scripts/lint/check-added-large-files.sh --max-kb=512 "$tmpdir/big.bin" && echo "FAIL: large file passed" || echo "OK: large file flagged"

# detect-private-key
printf -- '-----BEGIN TEST PRIVATE KEY-----\nabc\n-----END TEST PRIVATE KEY-----\n' >"$tmpdir/key.txt"
./scripts/lint/detect-private-key.sh "$tmpdir/key.txt" && echo "FAIL: key passed" || echo "OK: key flagged"

# trailing-whitespace
printf 'a \nb\n' >"$tmpdir/ws.txt"
./scripts/lint/trailing-whitespace.sh "$tmpdir/ws.txt"
grep -q ' $' "$tmpdir/ws.txt" && echo "FAIL: whitespace remained" || echo "OK: whitespace stripped"

rm -rf "$tmpdir"
```

Expected: 各行で `OK: ...` が出力される。`FAIL: ...` が出たら該当スクリプトを見直す。

- [ ] **Step 11: shellcheck で自己検査**

```bash
shellcheck scripts/lint/*.sh
```

Expected: エラーなし。警告があれば修正。

- [ ] **Step 12: コミット**

```bash
git add scripts/lint/
git commit -m "feat(pre-commit): add safety lint scripts for lefthook"
```

---

## Task 4: `lefthook.yml` 作成

**Files:**

- Create: `lefthook.yml`

- [ ] **Step 1: `lefthook.yml` を作成**

`lefthook.yml`:

```yaml
# Lefthook configuration.
# See https://lefthook.dev/configuration/ for details.
pre-commit:
  parallel: true
  commands:
    # ── セーフティ系 (pre-commit-hooks 相当) ──
    check-added-large-files:
      run: scripts/lint/check-added-large-files.sh --max-kb=512 {staged_files}
    check-json:
      glob: "*.json"
      run: scripts/lint/check-json.sh {staged_files}
    detect-aws-credentials:
      run: scripts/lint/detect-aws-credentials.sh --allow-missing-credentials {staged_files}
    detect-private-key:
      run: scripts/lint/detect-private-key.sh {staged_files}
    end-of-file-fixer:
      run: scripts/lint/end-of-file-fixer.sh {staged_files}
      stage_fixed: true
    mixed-line-ending:
      run: scripts/lint/mixed-line-ending.sh --fix=lf {staged_files}
      stage_fixed: true
    trailing-whitespace:
      run: scripts/lint/trailing-whitespace.sh {staged_files}
      stage_fixed: true

    # ── リンタ系 ──
    yamllint:
      glob: "*.{yml,yaml}"
      run: yamllint {staged_files}
    actionlint:
      glob: ".github/workflows/*.{yml,yaml}"
      run: actionlint {staged_files}
    shellcheck:
      glob: "*.sh"
      run: shellcheck {staged_files}
    markdownlint:
      glob: "*.{md,markdown}"
      run: pnpm exec markdownlint-cli2 --fix {staged_files}
      stage_fixed: true
    textlint:
      glob: "*.{md,markdown,txt}"
      run: pnpm exec textlint {staged_files}
    cspell:
      run: pnpm exec cspell lint --no-progress --no-must-find-files {staged_files}
    renovate-config-validator:
      glob: "renovate.json5"
      run: pnpm dlx --package=renovate renovate-config-validator {staged_files}

    # ── フォーマッタ系 ──
    biome-format:
      glob: "*.json"
      run: pnpm exec biome format --write {staged_files}
      stage_fixed: true
    terraform-fmt:
      glob: "*.tf"
      run: terraform fmt {staged_files}
      stage_fixed: true

# commit-msg / pre-push は現状不要。必要時にここへ追加。
```

- [ ] **Step 2: `lefthook install` でフック登録**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
lefthook install
```

Expected: `.git/hooks/pre-commit` が lefthook 版に差し替わる (prek install 分を上書き)。

- [ ] **Step 3: `lefthook run pre-commit --all-files` で全量検証**

```bash
lefthook run pre-commit --all-files 2>&1 | tee /tmp/lefthook-baseline.log
```

Expected: 全コマンドが PASS (SKIPPED は対象ファイル無しで OK)。失敗があれば該当フックを修正。

- [ ] **Step 4: Task 3 のベースラインとの差分を確認**

移行前 `prek run --all-files` ベースライン (全 18 フック PASS, commit `5aeb9d0`) と比較し、**検出結果が同等**であることを確認する。

```bash
# 参考: 移行前に取った prek ログを残している場合は差分比較。
# 無ければ、lefthook で --all-files 実行結果が全 PASS なら OK。
```

- [ ] **Step 5: コミット**

```bash
git add lefthook.yml
git commit -m "feat(pre-commit): add lefthook.yml with full hook set"
```

---

## Task 5: `justfile` の `setup` / `lint` を lefthook 化

**Files:**

- Modify: `justfile`

- [ ] **Step 1: 現行 `justfile` の該当レシピを確認**

```bash
sed -n '13,55p' /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit/justfile
```

- [ ] **Step 2: `setup` レシピを差し替え**

`justfile` の `setup:` ブロック全体を以下で置換:

```make
# Setup development environment
setup:
 @echo "Setting up development environment..."
 @if command -v mise >/dev/null 2>&1; then \
   echo "→ Installing tools with mise..."; \
   eval "$$(mise activate bash)"; \
   mise install; \
 else \
   echo "⚠ mise not found. Please run 'make bootstrap' first."; \
   exit 1; \
 fi
 @echo "→ Installing node dev dependencies with pnpm..."
 @pnpm install --frozen-lockfile
 @echo "→ Installing lefthook git hooks..."
 @lefthook install
 @echo "→ Initializing Terraform..."
 @cd {{terraform_dir}} && terraform init -upgrade
 @echo "✓ Setup complete!"
```

> 注: 既存の `terraform_dir := "terraform/src/repository"` が誤りで `terraform init` が失敗する既存バグがある。本 PR では `terraform_dir` の修正は対象外だが、もし発見済みなら別コミットで `terraform/src/repositories` に修正しても可。

- [ ] **Step 3: `lint` レシピを差し替え**

`justfile` の `lint:` ブロックを以下で置換:

```make
# Run all linters (lefthook)
lint:
 @echo "🔍 Running linters..."
 @lefthook run pre-commit --all-files
```

- [ ] **Step 4: `lint-hook` レシピを更新 (または削除)**

現行 `lint-hook hook:` は prek 専用。lefthook では以下で置換:

```make
# Run specific lefthook command
lint-hook hook:
 @lefthook run pre-commit --commands {{hook}} --all-files
```

- [ ] **Step 5: `just lint` で動作確認**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
just lint
```

Expected: lefthook の出力で全コマンド PASS / SKIPPED。

- [ ] **Step 6: `just lint-hook yamllint` で個別実行確認**

```bash
just lint-hook yamllint
```

Expected: yamllint のみ実行され PASS。

- [ ] **Step 7: コミット**

```bash
git add justfile
git commit -m "refactor(pre-commit): switch justfile setup/lint to lefthook"
```

---

## Task 6: `scripts/check-tools.sh` 更新

**Files:**

- Modify: `scripts/check-tools.sh`

- [ ] **Step 1: 現行スクリプトを確認**

```bash
cat /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit/scripts/check-tools.sh
```

- [ ] **Step 2: チェック対象を更新**

既存のチェック対象一覧から `prek` / `pre-commit` を削除し、`lefthook` / `pnpm` / `yamllint` / `actionlint` / `shellcheck` を追加する。

典型的な変更例 (実際の構造に応じて調整):

```bash
# 旧:
# tools=("mise" "terraform" "prek")
# 新:
tools=("mise" "terraform" "pnpm" "lefthook" "yamllint" "actionlint" "shellcheck")
```

- [ ] **Step 3: スクリプトを実行して通過するか確認**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
bash scripts/check-tools.sh
```

Expected: 全ツールが OK 扱い。

- [ ] **Step 4: shellcheck 実行**

```bash
shellcheck scripts/check-tools.sh
```

Expected: エラーなし。

- [ ] **Step 5: コミット**

```bash
git add scripts/check-tools.sh
git commit -m "refactor(pre-commit): update check-tools.sh for lefthook toolchain"
```

---

## Task 7: CI workflow の差し替え

**Files:**

- Create: `.github/workflows/lint.yml`
- Delete: `.github/workflows/prek.yml`

- [ ] **Step 1: `.github/workflows/lint.yml` を作成**

`.github/workflows/lint.yml`:

```yaml
---
name: lint

on:
  push:
    branches:
      - main
  pull_request:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}

jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
        with:
          ref: ${{ github.head_ref }}

      - name: Setup mise
        uses: jdx/mise-action@v2
        with:
          version: latest
          install: true

      - name: Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          run_install: false

      - name: Install node dependencies
        run: pnpm install --frozen-lockfile

      - name: Run lefthook
        run: lefthook run pre-commit --all-files
```

> `jdx/mise-action` と `pnpm/action-setup` のバージョン pin は実装時点の最新安定版 SHA に差し替え (CI ベストプラクティスに合わせる)。初期コミットはタグ参照でも可、Renovate が digest pin に変換する設定があればそちらに委ねる。

- [ ] **Step 2: 旧 workflow `prek.yml` を削除**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
git rm .github/workflows/prek.yml
```

- [ ] **Step 3: actionlint でローカル検証**

```bash
actionlint .github/workflows/lint.yml
```

Expected: エラーなし。

- [ ] **Step 4: yamllint でローカル検証**

```bash
yamllint .github/workflows/lint.yml
```

Expected: エラーなし。

- [ ] **Step 5: コミット**

```bash
git add .github/workflows/lint.yml
# prek.yml は step 2 の git rm で stage 済み
git commit -m "ci(pre-commit): replace prek workflow with lefthook"
```

---

## Task 8: `.pre-commit-config.yaml` 削除

**Files:**

- Delete: `.pre-commit-config.yaml`

- [ ] **Step 1: 参照箇所を最終確認**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
grep -rn "pre-commit-config" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null || echo "no references"
grep -rn "\.pre-commit-config\.yaml" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null || echo "no references"
```

Expected: ドキュメント (docs/ 配下の historical メモ) 以外から参照がないこと。参照があればまずそちらを更新。

- [ ] **Step 2: `.pre-commit-config.yaml` を削除**

```bash
git rm .pre-commit-config.yaml
```

- [ ] **Step 3: lefthook で最終ベースライン**

```bash
lefthook run pre-commit --all-files
```

Expected: 全コマンド PASS。

- [ ] **Step 4: コミット**

```bash
git commit -m "chore(pre-commit): remove .pre-commit-config.yaml"
```

---

## Task 9: 動作確認と Renovate 追跡確認

**Files:** なし (検証のみ)

- [ ] **Step 1: クリーンなステージで commit 検証**

軽微な変更を作って実際に `git commit` が通ることを確認:

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
echo "# test" >> /tmp/lefthook-test.md
git add /tmp/lefthook-test.md 2>/dev/null || true  # 失敗で OK (リポ外)

# リポ内で small change を作って試す
date > docs/_lefthook-smoke-test.tmp
git add docs/_lefthook-smoke-test.tmp
git commit -m "test: lefthook smoke" --allow-empty-message || true
git reset HEAD~1 --mixed  # コミットを巻き戻し
rm -f docs/_lefthook-smoke-test.tmp
```

Expected: lefthook が fired され、markdownlint / textlint / trailing-whitespace 等が走って PASS。

- [ ] **Step 2: 違反ケースの検出再現**

```bash
# trailing whitespace を意図的に混ぜる
printf 'bad line   \n' > docs/_lefthook-violation.md
git add docs/_lefthook-violation.md
lefthook run pre-commit --files docs/_lefthook-violation.md
# → trailing-whitespace が修正 (stage_fixed), markdownlint 系で他エラー無しなら PASS
cat docs/_lefthook-violation.md  # 行末空白が消えていることを確認
git restore --staged docs/_lefthook-violation.md
rm docs/_lefthook-violation.md
```

Expected: 行末空白が自動除去されている。

- [ ] **Step 3: renovate.json5 が検証されることを確認**

```bash
# renovate.json5 を軽微編集して lefthook 経由で検証 (構文エラーにならない変更)
cp renovate.json5 renovate.json5.bak
# 末尾改行の手動保証 (lefthook が自動で走る)
lefthook run pre-commit --files renovate.json5
# → renovate-config-validator が fired して PASS
mv renovate.json5.bak renovate.json5
```

Expected: `renovate-config-validator` が実行される (spec のバグ修正点の検証)。

- [ ] **Step 4: `.tool-versions` が Renovate で追跡対象か確認**

```bash
cat renovate.json5 | grep -i "tool-versions\|mise" || echo "mise/tool-versions 設定なし → preset で対応想定"
```

Renovate が `mise` manager / `.tool-versions` を追跡するよう preset が効いていることを確認。効いていなければ `renovate.json5` に `"mise"` を `enabledManagers` / preset 経由で追加する必要あり (本タスクでは検出のみ、変更は別 PR でも可)。

- [ ] **Step 5: PR を開いて CI が通ることを確認**

```bash
cd /Users/takeruooyama/workspace/tqer39/terraform-github-refactor/pre-commit
git push -u origin refactor/pre-commit
gh pr create --title "refactor(pre-commit): migrate to lefthook and prune unused hooks" \
  --body "$(cat <<'EOF'
## Summary
- `.pre-commit-config.yaml` + prek を `lefthook.yml` + mise/pnpm 管理に移行
- 不要フック 2 件削除 (`check-yaml`, `prettier` for GHA YAML)
- `renovate-config-validator` の `files` パターンを `renovate.json5` に修正
- `actionlint-docker` → native `actionlint` に置換

Spec: `docs/superpowers/specs/2026-04-18-ref-pre-commit-design.md`

## Test plan
- [ ] CI (lint workflow) が PASS
- [ ] ローカルで `just setup` → `just lint` が PASS
- [ ] 意図的違反 (trailing space, 不正 YAML) が検出される
EOF
)"
```

Expected: PR が作成され、CI が緑。

---

## Self-Review (完了判定)

実装者は本計画を完走した後、以下を確認:

- [ ] spec の「3. フック構成変更」の削除 2 / 修正 1 / 置換 1 がすべて反映
- [ ] spec の「5. コンポーネント」の 6 つ全て (`.tool-versions` / `package.json` / `lefthook.yml` / `scripts/lint/*.sh` / `justfile` / `.github/workflows/lint.yml`) が作成・更新済み
- [ ] spec の「8. テスト」の 5 項目をすべて実施
- [ ] 旧 `.pre-commit-config.yaml` と `prek.yml` が削除済み
- [ ] Renovate が `.tool-versions` と `package.json` を追跡する構成になっている
- [ ] PR CI が緑

すべて ✓ で本実装は完了。
