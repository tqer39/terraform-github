# workflow-result への lint 集約設計

## 背景

- PR の必須 status check は `workflow-result` 単一に統一済み（#1568）
- 現状 `lint` は独立した `.github/workflows/lint.yml` として動作しており、`workflow-result` の集約対象になっていない
- lint 失敗時にも `workflow-result` が成功判定されうるため、集約の完全性が損なわれている

## ゴール

`lint` ジョブを `terraform-github.yml` に取り込み、`workflow-result` が `lint` と terraform 系ジョブの完了をまとめて検査する状態にする。

## 変更内容

### 1. `.github/workflows/terraform-github.yml`

既存ジョブに `lint` を追加する。

- `runs-on: ubuntu-latest`、`timeout-minutes: 10`
- ステップは `lint.yml` の内容をそのまま移植:
  1. `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd`（`ref: ${{ github.head_ref }}`）
  2. `jdx/mise-action@1648a7812b9aeae629881980618f079932869151`（`install: true`）
  3. `pnpm/action-setup@fc06bc1257f339d1d5d8b3a19a8cae5388b55320`（`run_install: false`）
  4. `pnpm install --frozen-lockfile`
  5. betterleaks インストール（`BETTERLEAKS_VERSION: 1.1.2`）
  6. `lefthook run pre-commit --all-files`
- `needs` は指定しない（`set-matrix` と並列実行）
- `concurrency` は親 workflow の `terraform-github-${{ github.ref }}` に吸収されるため個別設定は不要

### 2. `workflow-result` ジョブの拡張

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

`lint.result` の検査を最初に行い、lint 失敗時は即座に `workflow-result` も失敗させる。

### 3. `.github/workflows/lint.yml` の削除

重複実行を防ぐため、統合後に削除する。

## 検証

- `just validate` で Terraform 設定に影響がないことを確認
- `actionlint` 相当の検査は lefthook が走れば検出されるが、YAML 構文は GitHub 側で評価されるため PR 作成時に要確認
- PR 作成後、`workflow-result` の `needs` に `lint` が含まれていることを Actions ログで確認

## 影響範囲

- リポジトリ設定の Required status check は `workflow-result` のままで変更不要
- `lint.yml` への外部参照はないため、削除による副作用は発生しない
- `push` イベント時の lint も継続実行される（挙動変更なし）

## 非対象

- Required status check 名の変更
- lefthook の設定変更
- 他 workflow（`terraform-import.yml` 等）の集約対応
