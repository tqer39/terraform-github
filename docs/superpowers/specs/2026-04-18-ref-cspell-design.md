# ref-cspell: cspell 辞書の外部ファイル化

作成日: 2026-04-18
ブランチ: `ref-cspell`

## 背景

本リポジトリの `cspell.json` は、設定項目（`files`, `ignorePaths`）と約 80 語の `words` 配列が 1 ファイルに同居している。辞書が増えるほど設定本体の可読性が下がり、差分レビューでもノイズになりやすい。加えて、同じ語のケース違い（`Hono`/`hono`、`Jellyfin`/`jellyfin` 等）が複数混在しており、cspell のデフォルト挙動（大文字小文字を区別しない）に対して冗長になっている。

## 目的

`cspell.json` から `words` 配列を外部辞書ファイルへ切り出し、設定ファイルの可読性を高める。同時にケース違いの重複を除去してリストを正規化する。

## 非目的（スコープ外）

- ワークスペース横断の共有辞書化（`renovate-config` のような別リポジトリ化）は行わない。将来必要になったら別件として扱う。
- `ignorePaths` や `files` の見直し。今回は触らない。
- 他の cspell 機能（`language`, `allowCompoundWords` など）の導入。

## 設計

### ファイル構成

- 外部辞書ファイル: `.cspell/project-words.txt`
  - 1 行 1 語
  - ソート順: 大文字小文字を区別しないアルファベット順
  - エンコーディング: UTF-8
  - 改行コード: LF
  - 末尾改行: あり

### `cspell.json` の変更

`words` 配列を削除し、外部辞書を参照する定義に置き換える。

変更後のスケルトン:

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

### 辞書の正規化ルール

cspell はデフォルトで大文字小文字を区別しないため、同一語のケース違いは冗長。次のルールで統一する。

1. 同一語のケース違いが存在する場合は **小文字版のみ残す**。
2. すべてが大文字の略語・定数名・慣習的にすべて大文字で書かれる識別子は元の表記を維持する。
3. アポストロフィや特殊記号を含む表記は、該当する通常表記に統合する（例: `O'oyama` → `ooyama`）。

#### 統合対象（小文字版を採用、大文字版は削除）

- `Autobuild` → `autobuild`
- `Hono` → `hono`
- `Jellyfin` → `jellyfin`
- `Komga` → `komga`
- `Audiobookshelf` → `audiobookshelf`
- `Vercel` → `vercel`
- `Worktrees` → `worktrees`

頭字語 `oidc`/`OIDC` は `OIDC` を維持して `oidc` を削除する（次項参照）。

#### 維持する大文字表記

- 頭字語・略語: `CODEOWNERS`, `FASTMCP`, `OIDC`, `OPENROUTER`, `SIGPIPE`, `SSIA`, `VITS`
- その他（小文字版なし）: `Brewfile`, `Takeru`

#### アポストロフィ入り表記

- `O'oyama` は **維持する**。cspell はアポストロフィを語分離子として扱うため、`ooyama` では `O'oyama` の綴りをカバーできない。`LICENSE` ファイルで実際に使用されているため必須。

## 検証

- `just lint`（pre-commit の cspell フック）が pass すること
- 外部辞書ファイル化の前後で `npx cspell lint '**/*.md' '**/*.json'` の結果に変化がないこと（語数減少による新規 false positive が出ないこと）
- `git diff` で `cspell.json` が簡潔になり、語彙本体は `.cspell/project-words.txt` に集約されていること

## 想定リスク

- ケース統合により、本来 cspell が検知すべき特定表記の誤字（例: `HONO` と書くべきところを `Hono` と書いた等）を見逃す可能性。ただし cspell のデフォルトが case-insensitive である以上、現状と挙動は変わらない。

## 参考

- cspell の `dictionaryDefinitions`: <https://cspell.org/configuration/dictionaries/>
