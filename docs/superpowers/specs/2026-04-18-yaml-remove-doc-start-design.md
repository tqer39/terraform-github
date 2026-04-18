# YAML document-start marker 除去設計 (2026-04-18)

## Context

リポジトリ内の YAML ファイルで、先頭の `---` (YAML document-start marker) が一部のみに付与されており、整合性が崩れている。

- `---` あり: 15 ファイル (`.github/` 配下 13 + `.pre-commit-config.yaml` + `.yamllint`)
- `---` なし: 5 ファイル (`.github/workflows/{auto-merge,terraform-import,set-common-github-secrets}.yml`、`.github/actions/{setup-terraform,aws-credential}/action.yml`)

すべての YAML で `---` を除去して「なし」に統一し、`.yamllint` のルールで再導入を禁止する。

## 方針決定

| 項目 | 決定 |
| ---- | ---- |
| 対象スコープ | リポジトリ全体の YAML (`.github/` + ルート設定 + `.yamllint`) |
| 再発防止 | yamllint で `document-start: {present: false, level: error}` に強化 |
| コミット粒度 | 2 コミット (除去 → ルール強化) |
| 実装手段 | 個別 Edit (15 ファイルで機械的に 1 行削除) |

## 対象ファイル

### Commit 1: `---` 除去 (15 ファイル)

- `.github/workflows/auto-assign.yml`
- `.github/workflows/generate-pr-description.yml`
- `.github/workflows/labeler.yml`
- `.github/workflows/prek.yml`
- `.github/workflows/terraform-github.yml`
- `.github/workflows/terraform-renovate.yml`
- `.github/workflows/update-license-year.yml`
- `.github/actions/set-matrix/action.yml`
- `.github/actions/terraform-apply/action.yml`
- `.github/actions/terraform-plan/action.yml`
- `.github/actions/terraform-validate/action.yml`
- `.github/labeler.yml`
- `.github/auto_assign.yml`
- `.pre-commit-config.yaml`
- `.yamllint`

すべて先頭 1 行が `---` のみの単一文書 YAML。`grep -c "^---$"` がすべて 1 であることを事前確認済み (多文書 YAML なし)。

### Commit 2: yamllint ルール強化

`.yamllint` の該当箇所を次のとおり変更:

```diff
-  document-start: disable
+  document-start:
+    present: false
+    level: error
```

他の `disable` 設定 (`document-end` など) は現状維持。

## 実施手順

1. **Commit 1: `refactor: remove YAML document-start marker from all configs`**
   1. 上記 15 ファイルから先頭 `---\n` を削除 (Edit ツールで逐次)
   2. `git ls-files '*.yml' '*.yaml' '.yamllint' | xargs -I{} sh -c 'head -1 "{}" | grep -q "^---$" && echo "{}"'` で残存ゼロを確認
   3. `prek run --all-files` でグリーンを確認 (yamllint は現状 disable 状態なので緩い)

2. **Commit 2: `chore(yamllint): forbid document-start marker`**
   1. `.yamllint` のルールを上記 diff のとおり変更
   2. `prek run yamllint --all-files` がグリーン (全ファイル `---` なしなので pass)
   3. 逆テスト: 任意 1 ファイルの先頭に `---` を仮挿入し `prek run yamllint` がエラーになることを確認 → 元に戻す

## 検証

- `prek run --all-files` がグリーン
- `prek run yamllint --all-files` がグリーン
- 逆テスト (`---` 挿入 → yamllint エラー → 戻す) が期待通り
- `git grep -n "^---$" -- '*.yml' '*.yaml' '.yamllint'` の結果がゼロ
- `just validate` (Terraform 検証) がグリーン (本変更と無関係だが念のため)

## リスクと緩和

- **yamllint v1.38 で `present: false` が期待どおり動作するか**: 逆テストで確認。想定通りでなければ upstream docs を参照して調整
- **他 worktree との整合**: 既存 3 worktree (`refactor/pre-commit`, `refactor/structure-brainstorm`, `feat/main-branch-protection-ruleset`) と対象ファイルは基本重ならない。マージ順次第で rebase により解消可能
- **除外対象の混入**: Markdown front matter や HCL は対象外。`git ls-files '*.yml' '*.yaml' '.yamllint'` のみに作用させるため巻き込みなし

## スコープ外

- Markdown front matter (`---` が意味的に必要)
- `terraform/**` の HCL (YAML ではない)
- プロジェクト外の依存先 (renovate-config のサブモジュール / vendor 配下)

## ロールバック

各コミットが独立しているため `git revert <sha>` で個別に戻せる。

## 参考

- `.yamllint` 現状: プロジェクトの formatting は Prettier、lint は yamllint (semantic のみ) という分担。`document-start` は現状 `disable` で意図的に黙認されていた
- 関連過去コミット: なし (今回が初の統一対応)
