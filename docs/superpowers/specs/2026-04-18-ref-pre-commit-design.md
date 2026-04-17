<!-- markdownlint-disable MD040 MD060 -->
<!-- cSpell:ignore tfsec AKIA lefthook yamllint actionlint shellcheck markdownlint textlint cspell biomejs dlx frozen jdx renovatebot -->

# ref-pre-commit: lefthook 移行と不要フック削除

- Date: 2026-04-18
- Status: Approved (design)
- Branch: `refactor/pre-commit`

## 1. 背景と目的

`terraform-github` は現状 `.pre-commit-config.yaml` (pre-commit / prek 両対応) で 18 フックを運用している。CI は `j178/prek-action` を採用しており、ローカル `just lint` も `prek run --all-files`。

運用上、以下の問題が表面化している。

- **バグ**: `renovate-config-validator` の `files: renovate.json` 指定が、実ファイル `renovate.json5` にマッチせず、バリデーションが実質無効
- **機能重複**: `check-yaml` と `yamllint` が YAML 構文検査で重複
- **メンテ負荷**: `prettier` (mirrors-prettier, archived) が GHA YAML 限定用途、`yamllint` + `actionlint` で代替可能
- **Docker 依存**: `actionlint-docker` はローカル実行で初回イメージ取得が遅い
- **ツール乱立**: pre-commit / prek / Docker / Node devDependencies が .pre-commit-config.yaml 内に混在し、依存関係が読みづらい

本リファクタでは、次の 2 つをまとめて実施する。

1. **lefthook (Go 製 hook runner) への移行** — 責務分離（依存宣言と実行計画）で設定可読性と再現性を高める
2. **不要フックの削除・不具合フックの修正・Docker 依存の解消**

## 2. スコープ外

- Terraform 向け追加フック (`tflint`, `terraform_validate`, `tfsec` 等) — 本リファクタでは追加しない。必要があれば別 spec で扱う
- 既存 `just` レシピのうち lint/setup 以外 (fmt, plan, apply 等) — 変更なし
- `cspell.json` / `.markdownlint.json` / `biome.json` などのルール設定 — 変更なし (既存運用を維持)

## 3. フック構成変更

### 3-1. 削除 (2 件)

| フック | 削除理由 |
|--------|---------|
| `check-yaml` (pre-commit-hooks) | `yamllint` が構文エラーも検出するため重複 |
| `prettier` (mirrors-prettier, GHA YAML 用) | `yamllint` + `actionlint` で十分、mirrors-prettier は archived |

### 3-2. 修正 (1 件)

| フック | 修正内容 |
|--------|---------|
| `renovate-config-validator` | ターゲットを `renovate.json5` に修正し、実際に検証が走るようにする |

### 3-3. 置換 (1 件)

| フック | 置換内容 |
|--------|---------|
| `actionlint-docker` | ネイティブ `actionlint` バイナリ (mise 管理) に置換し、Docker 依存を解消 |

### 3-4. 維持 (16 フック)

セーフティ系: `check-added-large-files`, `check-json`, `detect-aws-credentials`, `detect-private-key`, `end-of-file-fixer`, `mixed-line-ending`, `trailing-whitespace`

リンタ系: `yamllint`, `cspell`, `markdownlint-cli2`, `textlint`, `shellcheck`

フォーマッタ系: `biome-format` (JSON: `cspell.json`, `biome.json`, `.mcp.json`, `.vscode/*.json`, `.markdownlint.json` 等)、`terraform_fmt`

## 4. アーキテクチャ

責務分離を核とする 3 ファイル構成。

```
.tool-versions   ← CLI ツールのバージョン宣言 (mise が install)
package.json     ← Node ツールのバージョン宣言 (pnpm が install)
lefthook.yml     ← 実行計画 (どのフックをいつ/どのファイルに/どう呼ぶか)
```

lefthook は「ツールを呼び出す」だけで、インストール責務は持たない。ツール自体は mise と pnpm が解決する。Renovate は `.tool-versions` と `package.json` の両方を追跡対象にする。

## 5. コンポーネント

### 5-1. `.tool-versions` への追加

```
lefthook <latest>
yamllint <latest>
actionlint <latest>
shellcheck <latest>
```

(Terraform は既存のまま。各 `<latest>` は実装時点の最新安定版を固定し、以降は Renovate の `mise` manager が追従する)

### 5-2. `package.json` (新設)

```json
{
  "name": "terraform-github-devtools",
  "private": true,
  "packageManager": "pnpm@<latest>",
  "devDependencies": {
    "@biomejs/biome": "^1.9.4",
    "cspell": "^9.8.0",
    "markdownlint-cli2": "^0.22.0",
    "textlint": "^15.5.4",
    "textlint-filter-rule-allowlist": "^4.0.0",
    "textlint-filter-rule-comments": "^1.3.0",
    "textlint-rule-ja-no-space-between-full-width": "^2.4.2",
    "textlint-rule-no-dropping-the-ra": "^3.0.0",
    "textlint-rule-terminology": "^5.2.16"
  }
}
```

`pnpm-lock.yaml` も生成・コミットし、`frozen-lockfile` で CI/ローカルの再現性を担保。

### 5-3. `lefthook.yml` (新設)

```yaml
# staged ファイルに対して並列実行。--all-files で全量検査も可能。
pre-commit:
  parallel: true
  commands:
    # セーフティ系 (pre-commit-hooks 相当)
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

    # リンタ系
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

    # フォーマッタ系
    biome-format:
      glob: "*.json"
      run: pnpm exec biome format --write {staged_files}
      stage_fixed: true
    terraform-fmt:
      glob: "*.tf"
      run: terraform fmt {staged_files}
      stage_fixed: true

exclude:
  - USAGE.md
```

### 5-4. セーフティ系スクリプト (新設: `scripts/lint/*.sh`)

pre-commit-hooks の Python 実装は lefthook から直接呼び出せないため、同等機能の薄いシェルスクリプトを書き起こす。ロジックは最小（grep/awk/sed 程度）。

| ファイル | 内容 |
|---------|------|
| `scripts/lint/check-added-large-files.sh` | `--max-kb` を超えるステージファイルを検出 |
| `scripts/lint/check-json.sh` | `python -m json.tool` or `jq empty` で構文検査 |
| `scripts/lint/detect-aws-credentials.sh` | AKIA... 等のパターン検出、`--allow-missing-credentials` フラグ対応 |
| `scripts/lint/detect-private-key.sh` | `BEGIN * PRIVATE KEY` 等のヘッダ検出 |
| `scripts/lint/end-of-file-fixer.sh` | 末尾改行を保証 |
| `scripts/lint/mixed-line-ending.sh` | `--fix=lf` で LF 統一 |
| `scripts/lint/trailing-whitespace.sh` | 行末スペース除去 |

実装フェーズで既存の汎用 lefthook プラグイン・再利用可能スクリプト群を調査し、相当機能が再利用できるものがあればそちらを優先する (例: OSS の `.sh` テンプレ集)。見つからなければ自作で十分。ロジックが小さいので保守コストは低い。

### 5-5. `justfile` 差し替え

```makefile
# before
setup:
  ... prek install ...
lint:
  @prek run --all-files

# after
setup:
  ... lefthook install ... pnpm install --frozen-lockfile ...
lint:
  @lefthook run pre-commit --all-files
```

### 5-6. CI workflow 差し替え (`.github/workflows/prek.yml` → `lint.yml`)

```yaml
name: lint
on:
  push: { branches: [main] }
  pull_request:
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v6
      - uses: jdx/mise-action@<pinned>
      - uses: pnpm/action-setup@<pinned>
      - run: pnpm install --frozen-lockfile
      - run: lefthook run pre-commit --all-files
```

## 6. データフロー

```
git commit
  └─► lefthook pre-commit hook
        ├─► staged files を取得
        ├─► commands を glob でフィルタ → 並列実行 (parallel: true)
        │     └─► 各コマンドが mise/pnpm の PATH 経由でツールを呼び出し
        ├─► 失敗時: commit 中止、stderr 表示
        └─► stage_fixed: true の修正は自動で再 stage
```

CI 上では `lefthook run pre-commit --all-files` で全量検査。

## 7. エラーハンドリング

| 状況 | 挙動 |
|------|------|
| ツール未インストール | lefthook 起動直後の checker (`scripts/check-tools.sh`) が不足を報告、`mise install` / `pnpm install` を案内 |
| フック失敗 | `parallel: true` で他フックも並行実行・全件表示、lefthook が non-zero exit で commit 中止 |
| `stage_fixed` 付きフックの修正 | lefthook が自動で `git add`、ユーザ再操作不要 |
| Renovate が `pnpm-lock.yaml` を古くする | `frozen-lockfile` で CI が即検出、PR 段階で修正 |

## 8. テスト (検証計画)

1. **旧構成ベースライン**: 移行前に `prek run --all-files` が全 PASS することを記録（実施済み: 18 フック全 PASS, 5aeb9d0 時点）
2. **新構成ベースライン**: 移行後に `lefthook run pre-commit --all-files` が全 PASS
3. **検出再現テスト**: 意図的な違反 (trailing space, 無効 YAML, 未知語, 不正 `renovate.json5`) を staged にして各フックが検出することを確認
4. **CI 確認**: `.github/workflows/lint.yml` が新規 PR 上で成功
5. **新規クローン再現**: 別 worktree でゼロから `just setup` → `just lint` が通る

## 9. 移行ステップ (実装計画の粒度)

1. `package.json` + `pnpm-lock.yaml` 新設し、Node ツール単体で動作確認
2. `.tool-versions` に lefthook/yamllint/actionlint/shellcheck を追加
3. `lefthook.yml` + `scripts/lint/*.sh` を新設、`lefthook install`
4. `justfile` の `setup` / `lint` を lefthook 版に差し替え
5. `.github/workflows/lint.yml` 新設、`prek.yml` 削除
6. `.pre-commit-config.yaml` 削除、`scripts/check-tools.sh` 更新
7. Renovate が `.tool-versions` + `package.json` を追跡することを確認、必要なら `renovate.json5` を調整
8. PR で CI 緑確認 → merge

## 10. リスクと緩和

| リスク | 緩和 |
|--------|------|
| pre-commit-hooks 相当のシェル書き起こしにバグ | 既存入力で既存フックと同じ検出結果になることを差分テスト。万一プラグイン (e.g. lefthook-plugin-pre-commit-hooks) があればそちらを優先 |
| 他プロジェクト (terraform-aws 等) の規約と乖離 | 本プロジェクト単体で完結、他プロジェクトは本 spec の結果を見て独自判断 |
| Renovate が lefthook を追跡できない | mise の `.tool-versions` は renovate-config-presets で対応可能。確認後必要なら preset 追加 |
| 新 CI と旧 CI の両立期間で重複実行 | `prek.yml` を同 PR で削除、移行期間を持たない |

## 11. 非目標の再確認

- 本リファクタは**既存フックの機能と検出品質を維持**することが第一。ツール移行と不要削除のみ。新規リンタ導入は別 spec。
- `.pre-commit-config.yaml` の運用に慣れた貢献者向けドキュメント更新は移行後の README 修正で対応。
