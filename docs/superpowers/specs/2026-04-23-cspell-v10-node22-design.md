# cspell v10 対応: Node.js 22 へのアップグレード

作成日: 2026-04-23
関連 PR: [#1577](https://github.com/tqer39/terraform-github/pull/1577) (Renovate: cspell v9.8.0 → v10.0.0)
関連 CI 失敗: [run 24800456953](https://github.com/tqer39/terraform-github/actions/runs/24800456953/job/72581364113)

## 背景

Renovate が生成した PR #1577 で `cspell` が v9.8.0 から v10.0.0 に更新された。CI の lint ジョブで cspell フックが以下のエラーで失敗する。

```text
Unsupported NodeJS version (20.20.2); >=22.18.0 is required
```

cspell v10 は Node.js `>=22.18.0` を要求するが、現行 CI は GitHub Actions runner のデフォルト Node 20.20.2 を使っている。

### 現状の Node 管理

- `mise.toml` は `terraform`, `lefthook`, `yamllint`, `actionlint`, `shellcheck` のみ管理し、`node` は未指定。
- `.github/workflows/terraform-github.yml` の lint ジョブは `jdx/mise-action` と `pnpm/action-setup@v5`（`run_install: false`）のみ。`actions/setup-node` は使っていない。
- その結果、`pnpm install` および `lefthook` 配下の cspell は runner に pre-installed の Node 20 を使う。

## 目的

cspell v10 対応のために Node.js を 22 系に統一する。管理は `mise` 一本に寄せ、ローカルと CI で同じバージョンを使う。PR #1577 を緑にして cspell v10 へアップデートできる状態にする。

## 非目的（スコープ外）

- `pnpm` や他のツールのバージョン変更は行わない（既に `packageManager` で pinned）。
- cspell v10 で新しく追加された機能の利用・設定追加は行わない（挙動互換のみ確認）。
- 他リポジトリ（`blog`, `edu-quest` など）への Node 22 展開は扱わない。必要なら別件とする。
- GitHub Actions の runner イメージ自体の変更は行わない。

## 設計

### 採用アプローチ

`mise.toml` に `node` を追加し、CI 側は既存の `jdx/mise-action` ステップが `mise install` することで Node 22 を入れる。`actions/setup-node` は追加しない（管理の二重化を避けるため）。

### 変更内容

#### 1. `mise.toml`

`[tools]` に `node` を追加する。

```toml
[tools]
terraform = "1.14.8"
lefthook = "1.13.6"
yamllint = "1.38.0"
actionlint = "1.7.12"
shellcheck = "0.11.0"
node = "22"
```

バージョン指定は `"22"`（メジャー固定、mise が最新 22 系 LTS を解決）とする。cspell v10 の要件 `>=22.18.0` を満たしつつ、Renovate が mise-managed Node の更新を提案できるよう後で明示版へ寄せる判断は残せる形にする。

> 注: mise の `node = "22"` は最新の 22 系にフォールバックする。現時点で CI とローカルが同じバージョンを解決することが重要なので、将来的に明示バージョンへ切り替える場合は Renovate の `mise` datasource を使う別タスクで扱う。

#### 2. `.github/workflows/terraform-github.yml`

`Setup mise` ステップが `install: true` で `mise install` を実行するため、`mise.toml` の変更だけで CI にも反映される。**ワークフロー自体の変更はない**。

念のため、`pnpm install --frozen-lockfile` や `lefthook run pre-commit --all-files` が mise の shim 経由で Node 22 を使うことを検証する。`jdx/mise-action` は `$MISE_INSTALL_PATH/shims` を PATH に追加するため、mise 管理下の node が優先される想定。

#### 3. `package.json`

cspell v10 の要件を明示する目的で `engines.node` を追加する案もあるが、**今回は追加しない**。devDependency である cspell のランタイム要件は mise / CI の制約で担保されており、`engines` を足すと `pnpm install` の警告/失敗挙動が変わり副作用が出うるため。将来的に必要と分かった時点で別件で扱う。

#### 4. PR #1577 への反映

この spec の実装ブランチをマージ後、PR #1577 を rebase/再実行することで CI を通す。PR #1577 自体のコミットはこのブランチには含めない（Renovate PR に手を加えると再生成の運用が混乱するため）。

### 変更するファイル（最終確定）

- `mise.toml` — `node = "22"` を追加（1 行）

その他のファイル変更は**不要**。

## 検証

1. ローカル（この worktree）で:
   - `mise install` 後、`mise exec -- node --version` が `v22.x.y` （`>=22.18.0`）を返す。
   - `pnpm install --frozen-lockfile` が成功する。
   - `lefthook run pre-commit --all-files` が pass する（cspell 含む全フック）。
2. CI で:
   - 本ブランチの PR で lint ジョブが緑になる。
   - PR #1577 を rebase 後、lint ジョブの cspell フックでエラーメッセージが解消し、lint ジョブ全体が緑になる。

## 想定リスク

- **mise の `node = "22"` が CI 毎に異なる最新 22 系を解決する**: runner 間でごくわずかなパッチ差分が出る可能性。cspell v10 の要件 `>=22.18.0` を満たす限り問題ない。再現性を厳密にしたい場合は後日 `22.x.y` へ明示バージョン化する。
- **既存の `pnpm/action-setup` と mise の Node が競合する可能性**: pnpm action は Node を提供しない（`run_install: false`）ため、PATH 上の Node（mise shim）が使われる想定。検証で確認する。
- **ローカル開発者の Node バージョン差**: `mise.toml` コミット後、ローカルで `mise install` の再実行が必要。CLAUDE.md / README に Node 追加の告知は不要（mise は既存ワークフローに従う運用）。

## 参考

- cspell v10 リリースノート（import-fresh v4 への更新により Node 要件が上がった）: <https://github.com/streetsidesoftware/cspell/blob/HEAD/packages/cspell/CHANGELOG.md>
- mise の tools 指定: <https://mise.jdx.dev/configuration.html>
