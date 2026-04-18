# ref-cspell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `cspell.json` の `words` 配列を `.cspell/project-words.txt` へ外部化し、ケース違いの重複を除去する。

**Architecture:** cspell の `dictionaryDefinitions` + `dictionaries` 機能で外部テキスト辞書を参照する。辞書ファイルは 1 行 1 語、大文字小文字を区別しないアルファベット順、UTF-8 / LF / 末尾改行あり。

**Tech Stack:** cspell (v9.8.0 via pre-commit / prek), JSON設定

**Spec:** `docs/superpowers/specs/2026-04-18-ref-cspell-design.md`

---

## File Structure

- Create: `.cspell/project-words.txt` — 外部辞書ファイル（73 語）
- Modify: `cspell.json` — `words` 配列を削除し `dictionaryDefinitions` / `dictionaries` を追加

---

### Task 1: 外部辞書ファイル `.cspell/project-words.txt` を作成

**Files:**

- Create: `.cspell/project-words.txt`

**Context:** 既存 `cspell.json` の `words` 配列（83 語）から、ケース違い重複 10 語を除去した 73 語を、大文字小文字を区別しないアルファベット順で並べる。

除去した 10 語とその統合先:

- `Autobuild` → `autobuild`
- `Hono` → `hono`
- `Jellyfin` → `jellyfin`
- `Komga` → `komga`
- `Audiobookshelf` → `audiobookshelf`
- `O'oyama` → `ooyama`
- `oidc` → `OIDC`（頭字語なので大文字を維持）
- `Vercel` → `vercel`
- `vits` → `VITS`（頭字語なので大文字を維持）
- `Worktrees` → `worktrees`

- [ ] **Step 1: `.cspell/` ディレクトリを作成**

Run: `mkdir -p .cspell`

- [ ] **Step 2: `.cspell/project-words.txt` を以下の内容で作成**

```text
audiobookshelf
autobuild
autofix
automerge
autoupdate
awslabs
bobheadxi
Brewfile
buildscript
bypassers
chdir
codecov
CODEOWNERS
codeql
comfyui
concat
deployments
edu-quest
elif
exitcode
fastapi
FASTMCP
frontmatter
getsentry
homelab
hono
itkq
jellyfin
justfile
kentaro
kintai
kkhs
komga
linuxbrew
litagin
markdownlint
mathquest
mise
nana
nextjs
nochange
nodenv
noreply
OIDC
oneline
ooyama
openclaw
OPENROUTER
prek
pyenv
pyproject
reviewdog
rinchsan
shellcheck
shellenv
SIGPIPE
SSIA
Takeru
textlint
textlintcache
textlintignore
textlintrc
tfcmt
tfenv
tflint
tfstate
toplevel
tqer
vercel
VITS
worktree
worktrees
xtrade
```

末尾に改行 1 つ（LF）。BOM なし、UTF-8。

- [ ] **Step 3: 行数と書式を検証**

Run:

```bash
wc -l .cspell/project-words.txt
file .cspell/project-words.txt
```

Expected:

- `wc -l` の出力が `73 .cspell/project-words.txt`
- `file` コマンドで `UTF-8` または `ASCII` テキストと表示される
- CRLF が含まれないこと

追加検証:

```bash
LC_ALL=C awk '{print tolower($0)}' .cspell/project-words.txt | diff - <(LC_ALL=C awk '{print tolower($0)}' .cspell/project-words.txt | LC_ALL=C sort)
```

Expected: 差分なし（= ソート順が正しい）

---

### Task 2: `cspell.json` を外部辞書参照に書き換え

**Files:**

- Modify: `cspell.json`

- [ ] **Step 1: 現在の `cspell.json` の内容を確認（変更前のバックアップ比較用）**

Run: `cat cspell.json | head -15`

Expected: `"words": [` で始まる配列が 11 行目付近から存在する。

- [ ] **Step 2: `cspell.json` を以下の内容に置き換える**

```json
{
  "files": ["**", ".*/**"],
  "ignorePaths": [
    ".git",
    ".gitignore",
    ".serena",
    ".vscode",
    ".pre-commit-config.yaml",
    "pyproject.toml"
  ],
  "dictionaryDefinitions": [
    {
      "name": "project-words",
      "path": ".cspell/project-words.txt",
      "addWords": true
    }
  ],
  "dictionaries": ["project-words"]
}
```

`words` 配列は完全に削除する。`files` と `ignorePaths` は既存値を維持。

- [ ] **Step 3: JSON として妥当性を確認**

Run: `python3 -c "import json; json.load(open('cspell.json'))" && echo OK`

Expected: `OK`

---

### Task 3: cspell フックで既存ファイルの lint が通ることを検証

**Files:** なし（検証のみ）

- [ ] **Step 1: cspell フック単体を実行**

Run: `just lint-hook cspell`

Expected: `Passed` で終了。新規の spell エラーなし。

- [ ] **Step 2: 全 pre-commit フックを実行**

Run: `just lint`

Expected: すべての hook が `Passed` か `Skipped`。cspell で未知語エラーが出ないこと。

- [ ] **Step 3: エラーが出た場合の対処**

`Unknown word` が報告された語が存在する場合、その語は Task 1 の削除対象ケース違いの誤統合か、ソート漏れの可能性がある。`.cspell/project-words.txt` を確認し、元の `cspell.json` の `words` 配列（`git show HEAD~1:cspell.json`）と照合して不足語を補完する。補完後に Step 1 に戻る。

---

### Task 4: コミット

**Files:** なし（git 操作のみ）

- [ ] **Step 1: 変更ファイルを確認**

Run: `git status --short`

Expected:

```text
 M cspell.json
?? .cspell/project-words.txt
```

- [ ] **Step 2: ステージングしてコミット**

Run:

```bash
git add .cspell/project-words.txt cspell.json
git commit -m "refactor(cspell): 辞書を .cspell/project-words.txt へ外部化"
```

- [ ] **Step 3: 差分サマリを確認**

Run: `git show --stat HEAD`

Expected:

- `.cspell/project-words.txt` が 73 行追加
- `cspell.json` の差分が `words` 配列削除と `dictionaryDefinitions` / `dictionaries` の追加

---

## Completion Criteria

- `.cspell/project-words.txt` が 73 語・UTF-8・LF・末尾改行ありで存在する
- `cspell.json` に `words` 配列が存在せず、`dictionaryDefinitions` と `dictionaries` で外部辞書を参照している
- `just lint` が pass する
- 上記 2 変更が 1 コミットにまとまっている
