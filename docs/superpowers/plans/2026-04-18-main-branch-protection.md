# Main Branch Protection Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `terraform-github` モジュールに「1 人向け標準 `main` ブランチ保護 ruleset」を opt-out 方式で内蔵し、まず PR1 スコープ（モジュール変更 + `terraform-github` 自身の移行 + archived 3 件のクリーンアップ + docs 更新）を完了させる。

**Architecture:** `terraform/modules/repository/github_repository_ruleset.tf` に新リソース `github_repository_ruleset.default_main_protection` を追加。`var.disable_default_main_protection`（デフォルト `false`）で opt-out できる。既存 `github_repository_ruleset.this`（`for_each = var.branch_rulesets`）とは共存し、`lifecycle.precondition` で `"main"` キーの重複を弾く。

**Tech Stack:** Terraform 1.14.8, GitHub Provider 6.11.1, remote S3 backend（repo ごとに独立した state）、prek (pre-commit)、markdownlint-cli2。

**Reference spec:** `docs/superpowers/specs/2026-04-18-main-branch-protection-design.md`

---

## Working Directory

すべての作業は worktree のルートで行う。以下、コマンドで出てくる `cd "$(git rev-parse --show-toplevel)"` は「このプラン用の worktree ルートに戻る」意味。

ブランチは `feat/main-branch-protection-ruleset`。`main` へ push しない。

## File Structure

| File | Responsibility | 変更種別 |
| --- | --- | --- |
| `terraform/modules/repository/variables.tf` | 新 var 2 つ（`disable_default_main_protection`, `default_main_protection_owner_bypass`）を追加 | Modify |
| `terraform/modules/repository/github_repository_ruleset.tf` | `github_repository_ruleset.default_main_protection` リソースと既存 `this` への `lifecycle.precondition` を追加 | Modify |
| `terraform/src/repositories/terraform-github/main.tf` | `branch_rulesets."main"` と `enable_owner_bypass` を削除。新デフォルト保護に寄せる | Modify |
| `terraform/src/repositories/obsidian-vault-old/main.tf` | `disable_default_main_protection = true` + `visibility = "private"`（public の場合） | Modify |
| `terraform/src/repositories/setup-develop-environments/main.tf` | `disable_default_main_protection = true` + `visibility = "private"`（public の場合） | Modify |
| `terraform/src/repositories/local-workspace-provisioning/main.tf` | `branch_rulesets."main"` 削除 + `disable_default_main_protection = true` + `visibility = "private"`（public の場合） | Modify |
| `docs/terraform-patterns.md` | opt-out デフォルト方式を冒頭に追記 | Modify |
| `docs/coding-standards.md` | 新規 repo 追加時の標準保護を追記 | Modify |

---

## Task 1: モジュールに新 variable を 2 つ追加

**Files:**

- Modify: `terraform/modules/repository/variables.tf`（末尾、`variable "enable_owner_bypass"` の直後に追加）

- [ ] **Step 1: variables.tf を開いて既存内容を確認**

Run（worktree ルートから実行）: `sed -n '180,190p' terraform/modules/repository/variables.tf`

Expected output 最後:

```hcl
variable "enable_owner_bypass" {
  type        = bool
  description = "(Optional) Whether to allow repository admins to bypass branch protection rules."
  default     = false
}
```

- [ ] **Step 2: 2 つの variable を追加**

`variable "enable_owner_bypass"` ブロックの直後（L186 の次行）に、以下を追加:

```hcl

variable "disable_default_main_protection" {
  type        = bool
  description = "(Optional) true にすると、標準 main ブランチ保護 ruleset を無効化する。obsidian-vault など保護不要な repo 用。"
  default     = false
}

variable "default_main_protection_owner_bypass" {
  type        = bool
  description = "(Optional) 標準 main ブランチ保護で、リポジトリ所有者による bypass を許可するか。既存 enable_owner_bypass と同じ semantics（bypass_mode = pull_request）。"
  default     = true
}
```

- [ ] **Step 3: terraform fmt で整形**

Run:

```bash
cd "$(git rev-parse --show-toplevel)"
terraform fmt terraform/modules/repository/variables.tf
```

Expected: ファイルパスが表示されるか、何も出ない（整形対象が無い）。

- [ ] **Step 4: コミット**

```bash
git add terraform/modules/repository/variables.tf
git commit -m "feat: モジュールに default_main_protection 用の変数を 2 つ追加

- disable_default_main_protection: opt-out フラグ（デフォルト false）
- default_main_protection_owner_bypass: 所有者 bypass 許可フラグ（デフォルト true）"
```

---

## Task 2: `github_repository_ruleset.default_main_protection` リソースを追加

**Files:**

- Modify: `terraform/modules/repository/github_repository_ruleset.tf`（ファイル末尾、既存 `github_repository_ruleset.this` の直後に追加）

- [ ] **Step 1: 現状の末尾を確認**

Run: `tail -10 terraform/modules/repository/github_repository_ruleset.tf`

Expected: 既存 `this` リソースの閉じ `}` が L111 にある。

- [ ] **Step 2: 新リソースを追加**

`terraform/modules/repository/github_repository_ruleset.tf` の末尾（L111 の `}` の直後、空行を 1 つ挟む）に以下を追加:

```hcl

# Default "1人向け標準" main branch protection ruleset.
# opt-out 方式: disable_default_main_protection = true で無効化可能。
# 詳細は docs/superpowers/specs/2026-04-18-main-branch-protection-design.md を参照。
resource "github_repository_ruleset" "default_main_protection" {
  count       = var.disable_default_main_protection ? 0 : 1
  name        = "main"
  repository  = local.repository_name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      required_review_thread_resolution = true
    }

    required_status_checks {
      strict_required_status_checks_policy = false
      required_check {
        context = "workflow-result"
      }
    }
  }

  dynamic "bypass_actors" {
    for_each = var.default_main_protection_owner_bypass ? [1] : []
    content {
      actor_id    = 5 # Admin role ID
      actor_type  = "RepositoryRole"
      bypass_mode = "pull_request"
    }
  }

  depends_on = [
    github_repository.this,
    github_repository.this_from_template,
  ]
}
```

- [ ] **Step 3: terraform fmt**

```bash
terraform fmt terraform/modules/repository/github_repository_ruleset.tf
```

Expected: 変更ファイル名の出力または何も出ない。

- [ ] **Step 4: コミット**

```bash
git add terraform/modules/repository/github_repository_ruleset.tf
git commit -m "feat: default_main_protection リソースをモジュールに追加

opt-out デフォルトで main ブランチを保護する新リソース。
force push 禁止 / 削除禁止 / linear history / PR 必須 / approvals 0 /
workflow-result 必須 / 所有者 PR bypass 可能。"
```

---

## Task 3: `github_repository_ruleset.this` に precondition を追加

既存 `this` リソースに lifecycle.precondition を足して、`branch_rulesets."main"` と `default_main_protection` の共存を弾く。

**Files:**

- Modify: `terraform/modules/repository/github_repository_ruleset.tf`（既存 `this` リソースに lifecycle ブロック追加）

- [ ] **Step 1: 既存 `this` の末尾（L107-L111）を確認**

Run: `sed -n '105,111p' terraform/modules/repository/github_repository_ruleset.tf`

Expected output:

```hcl
  }

  depends_on = [
    github_repository.this,
    github_repository.this_from_template,
  ]
}
```

- [ ] **Step 2: `depends_on` ブロックの直前に lifecycle.precondition を追加**

`depends_on` の直前に以下を挿入:

```hcl
  lifecycle {
    precondition {
      condition     = var.disable_default_main_protection || each.key != "main"
      error_message = "branch_rulesets に \"main\" エントリを置く場合は、モジュール呼び出し側で disable_default_main_protection = true にして default_main_protection を無効化してください。両方有効だと GitHub 側で ruleset 名が重複してエラーになります。"
    }
  }

```

結果:

```hcl
  }

  lifecycle {
    precondition {
      condition     = var.disable_default_main_protection || each.key != "main"
      error_message = "branch_rulesets に \"main\" エントリを置く場合は、モジュール呼び出し側で disable_default_main_protection = true にして default_main_protection を無効化してください。両方有効だと GitHub 側で ruleset 名が重複してエラーになります。"
    }
  }

  depends_on = [
    github_repository.this,
    github_repository.this_from_template,
  ]
}
```

- [ ] **Step 3: terraform fmt**

```bash
terraform fmt terraform/modules/repository/github_repository_ruleset.tf
```

- [ ] **Step 4: terraform-github repo で validate を実行**

各 repo は自分の state backend を使うため、validate は repo ディレクトリで行う。

```bash
cd terraform/src/repositories/terraform-github
terraform init -upgrade
terraform validate
```

Expected:

- `terraform init -upgrade`: backend 初期化成功
- `terraform validate`: **Success! The configuration is valid.**

このとき `terraform plan` はまだ流さない（precondition が現 branch_rulesets と衝突するため）。

```bash
cd "$(git rev-parse --show-toplevel)"
```

- [ ] **Step 5: コミット**

```bash
git add terraform/modules/repository/github_repository_ruleset.tf
git commit -m "feat: branch_rulesets.\"main\" と default_main_protection の共存を precondition で禁止

両方有効にすると GitHub 側で ruleset 名が重複するため、
変数で明示的に disable_default_main_protection=true を設定させる。"
```

---

## Task 4: `terraform-github` 自身を新デフォルトに移行（コード修正）

**Files:**

- Modify: `terraform/src/repositories/terraform-github/main.tf`

- [ ] **Step 1: 現状を確認**

Run: `cat terraform/src/repositories/terraform-github/main.tf`

Expected: L7 に `enable_owner_bypass = true`、L10-L39 に `branch_rulesets = { "main" = { ... } }` がある。

- [ ] **Step 2: `enable_owner_bypass` と `branch_rulesets` ブロックを削除**

次の内容でファイルを置換する。

```hcl
module "this" {
  source         = "../../../modules/repository"
  github_token   = var.github_token
  repository     = "terraform-github"
  owner          = "tqer39"
  default_branch = "main"
  topics         = ["terraform", "github"]
  description    = "Configure GitHub resources with Terraform."
}
```

- [ ] **Step 3: terraform fmt**

```bash
terraform fmt terraform/src/repositories/terraform-github/main.tf
```

- [ ] **Step 4: validate を実行**

```bash
cd terraform/src/repositories/terraform-github
terraform validate
cd "$(git rev-parse --show-toplevel)"
```

Expected: Success。

---

## Task 5: `terraform-github` の state mv と plan 検証

**重要:** このタスクは **remote state** を直接操作する。実行前に state をバックアップし、plan で想定差分であることを **ユーザーが目視確認** してから進む。

- [ ] **Step 1: state backup**

```bash
cd terraform/src/repositories/terraform-github
terraform init -upgrade
terraform state pull > /tmp/terraform-github-before-mv.tfstate
ls -l /tmp/terraform-github-before-mv.tfstate
```

Expected: ファイルサイズ > 0 のバックアップファイルが作られる。

- [ ] **Step 2: 現状の state 上のリソース名を確認**

```bash
terraform state list | grep github_repository_ruleset
```

Expected:

```text
module.this.github_repository_ruleset.this["main"]
```

- [ ] **Step 3: state mv を実行**

```bash
terraform state mv \
  'module.this.github_repository_ruleset.this["main"]' \
  'module.this.github_repository_ruleset.default_main_protection[0]'
```

Expected: `Move "module.this.github_repository_ruleset.this[\"main\"]" to "module.this.github_repository_ruleset.default_main_protection[0]"` + `Successfully moved 1 object(s).`

- [ ] **Step 4: 新しい state 配置を確認**

```bash
terraform state list | grep github_repository_ruleset
```

Expected:

```text
module.this.github_repository_ruleset.default_main_protection[0]
```

（`.this["main"]` は消えている）

- [ ] **Step 5: plan で差分確認**

```bash
terraform plan -out /tmp/terraform-github-migrate.tfplan
```

**期待される差分（~ update in-place の 1 件）:**

- `required_approving_review_count: 1 -> 0`
- `required_review_thread_resolution: (既に true で差分なし)`
- `required_status_checks.required_check`: `[{ context = "prek" }, { context = "workflow-result" }]` → `[{ context = "workflow-result" }]`（prek が除かれる）
- `required_status_checks.strict_required_status_checks_policy: true -> false`
- `rules.deletion: false -> true`
- `rules.non_fast_forward: false -> true`
- `rules.required_linear_history: (既に true で差分なし)`
- `bypass_actors.0.bypass_mode`: 変化なし（共に pull_request）

**中止シグナル:**

- `-/+ destroy and then create` が出ている → state mv 失敗。state を /tmp バックアップから復元して調査。
- 差分が 0 件 → default_main_protection リソース側の設定が既存と完全一致していないか、state mv が上書きされていない可能性。

- [ ] **Step 6: 差分をユーザーに共有して apply 判断を仰ぐ**

plan 出力を表示してユーザーに apply 可否を確認する。ユーザーの許可なしに apply しない。

- [ ] **Step 7: ユーザー許可後 apply**

```bash
terraform apply /tmp/terraform-github-migrate.tfplan
```

Expected: 1 change applied successfully。

- [ ] **Step 8: GitHub UI で ruleset を目視確認**

ブラウザで <https://github.com/tqer39/terraform-github/rules> を開き、`main` ruleset が 1 つ存在し以下であることを確認:

- Enforcement: Active
- Target: Default branch
- Rules: Restrict deletions / Block force pushes / Require linear history / Require PR before merging (approvals=0) / Require status checks (workflow-result)
- Bypass actors: Repository admin (Pull request)

- [ ] **Step 9: worktree ルートに戻る**

```bash
cd "$(git rev-parse --show-toplevel)"
```

- [ ] **Step 10: コミット**

```bash
git add terraform/src/repositories/terraform-github/main.tf
git commit -m "feat(terraform-github): default_main_protection に移行

branch_rulesets.\"main\" と enable_owner_bypass を削除。
モジュールの default_main_protection に寄せた（approvals 1→0、
required_status_checks は workflow-result のみ、strict=false に変更）。"
```

---

## Task 6: archived 3 件を `disable_default_main_protection = true` + `private` 化

**対象:**

- `local-workspace-provisioning`（現在 ruleset 設定あり）
- `obsidian-vault-old`（branch_rulesets = {}）
- `setup-develop-environments`（branch_rulesets キー無し）

各 repo について以下を実施する。テンプレートは同じだが、内容は少しずつ違う。

### 6-1: `local-workspace-provisioning`

- [ ] **Step 1: 現状確認**

```bash
cat terraform/src/repositories/local-workspace-provisioning/main.tf
```

`visibility` が何かを確認（`public` / `private` / 未指定＝`public`）。`archived = true` があることを確認。`branch_rulesets` に `"main"` エントリがあることを確認。

- [ ] **Step 2: `main.tf` を修正**

以下のルールで編集:

1. `branch_rulesets` の `"main"` エントリを削除（丸ごと `branch_rulesets = { ... }` を消してよい、`main` 以外のエントリが無い前提）。もし他のエントリがあれば `"main"` のみ消す。
2. `enable_owner_bypass = true` があれば削除。
3. `disable_default_main_protection = true` を追加。
4. `visibility` が `public` または未指定の場合、`visibility = "private"` に変更または追加。

- [ ] **Step 3: terraform fmt**

```bash
terraform fmt terraform/src/repositories/local-workspace-provisioning/main.tf
```

- [ ] **Step 4: init + validate + plan**

```bash
cd terraform/src/repositories/local-workspace-provisioning
terraform init -upgrade
terraform validate
terraform plan -out /tmp/local-workspace-provisioning.tfplan
```

**期待される差分:**

- `github_repository_ruleset.this["main"]` の **destroy**（state から消える）
- `module.this.github_repository.this.visibility: "public" -> "private"`（public だった場合のみ）
- `module.this.github_repository_ruleset.default_main_protection`: 作成されないこと（`count = 0` のため、差分に出ない）

- [ ] **Step 5: ユーザー確認の上 apply**

```bash
terraform apply /tmp/local-workspace-provisioning.tfplan
```

- [ ] **Step 6: worktree ルートに戻る**

```bash
cd "$(git rev-parse --show-toplevel)"
```

### 6-2: `obsidian-vault-old`

- [ ] **Step 1: 現状確認**

```bash
cat terraform/src/repositories/obsidian-vault-old/main.tf
```

`visibility` と `archived = true` と `branch_rulesets = {}` があることを確認。

- [ ] **Step 2: `main.tf` を修正**

1. `branch_rulesets = {}` は削除してよい（モジュールのデフォルト値が `{}` なので省略可）。残しても動作は変わらない。
2. `enable_owner_bypass = true` があれば削除（`branch_rulesets` が空なので意味がない）。
3. `disable_default_main_protection = true` を追加。
4. `visibility` が `public` または未指定の場合、`visibility = "private"` に変更または追加。

- [ ] **Step 3: terraform fmt**

```bash
terraform fmt terraform/src/repositories/obsidian-vault-old/main.tf
```

- [ ] **Step 4: init + validate + plan**

```bash
cd terraform/src/repositories/obsidian-vault-old
terraform init -upgrade
terraform validate
terraform plan -out /tmp/obsidian-vault-old.tfplan
```

**期待される差分:**

- `module.this.github_repository.this.visibility: "public" -> "private"`（public だった場合のみ）
- ruleset 関連の差分は無い（既に ruleset 無し、新標準も `count = 0` で作られない）

- [ ] **Step 5: ユーザー確認の上 apply**

```bash
terraform apply /tmp/obsidian-vault-old.tfplan
```

- [ ] **Step 6: worktree ルートに戻る**

```bash
cd "$(git rev-parse --show-toplevel)"
```

### 6-3: `setup-develop-environments`

- [ ] **Step 1: 現状確認**

```bash
cat terraform/src/repositories/setup-develop-environments/main.tf
```

`visibility` と `archived = true` と、`branch_rulesets` キーが存在しないことを確認。

- [ ] **Step 2: `main.tf` を修正**

1. `disable_default_main_protection = true` を追加。
2. `visibility` が `public` または未指定の場合、`visibility = "private"` に変更または追加。

- [ ] **Step 3: terraform fmt**

```bash
terraform fmt terraform/src/repositories/setup-develop-environments/main.tf
```

- [ ] **Step 4: init + validate + plan**

```bash
cd terraform/src/repositories/setup-develop-environments
terraform init -upgrade
terraform validate
terraform plan -out /tmp/setup-develop-environments.tfplan
```

**期待される差分:**

- `module.this.github_repository.this.visibility: "public" -> "private"`（public だった場合のみ）
- ruleset 関連の差分は無い（元々存在せず、新標準も `count = 0` で作られない）

- [ ] **Step 5: ユーザー確認の上 apply**

```bash
terraform apply /tmp/setup-develop-environments.tfplan
```

- [ ] **Step 6: worktree ルートに戻る**

```bash
cd "$(git rev-parse --show-toplevel)"
```

### 6-4: 3 件をまとめてコミット

- [ ] **Step 1: 3 件の変更をコミット**

```bash
git add terraform/src/repositories/local-workspace-provisioning/main.tf \
        terraform/src/repositories/obsidian-vault-old/main.tf \
        terraform/src/repositories/setup-develop-environments/main.tf
git commit -m "chore(archived): disable_default_main_protection=true + private 化

archived 3 件をモジュール標準保護の適用対象外にし、visibility を
private に揃える（public のものは private へ変更）。"
```

---

## Task 7: docs の更新

**Files:**

- Modify: `docs/terraform-patterns.md`
- Modify: `docs/coding-standards.md`

- [ ] **Step 1: `docs/terraform-patterns.md` を開いて現状確認**

Run: `head -60 docs/terraform-patterns.md`

- [ ] **Step 2: `docs/terraform-patterns.md` の「branch_rulesets」節の先頭に新方針を追記**

既存の `branch_rulesets` 説明セクション（L5 付近）の **直前** に次のセクションを追加:

```markdown
## 標準 main ブランチ保護（opt-out デフォルト）

`terraform/modules/repository` はデフォルトで `main` ブランチの標準保護 ruleset を作成する（`github_repository_ruleset.default_main_protection`）。含まれるルール:

- Force push 禁止 / 削除禁止 / linear history 必須
- PR 必須、承認数 0、レビュー thread 未解決時はマージ不可
- Status checks 必須（`workflow-result`）
- リポジトリ所有者は PR context でのみ bypass 可能

### 無効化する場合

`disable_default_main_protection = true` を `module "this" { ... }` に追加すると、標準 ruleset を作らなくなる。例外用途（`obsidian-vault` など保護不要 repo、archived repo）で使う。

### 独自 ruleset を書く場合

`branch_rulesets` で `"main"` 以外の名前の ruleset は自由に追加できる。`"main"` を上書きしたい場合は `disable_default_main_protection = true` にしてから `branch_rulesets."main"` を書く（precondition が衝突を弾く）。
```

- [ ] **Step 3: 既存 `branch_rulesets` 例の不整合を確認して修正**

`docs/terraform-patterns.md` 内で `require_code_owner_review = true` の例があれば、実装側に合わせて `false` に修正（実装と例のズレを解消）。他に approvals 数や context 名の記述があれば、新標準（approvals=0, workflow-result）と整合させる。

Run: `grep -n 'require_code_owner_review\|required_approving_review_count\|context' docs/terraform-patterns.md`

該当行を目視で確認し、実装 (`terraform/modules/repository/github_repository_ruleset.tf`) と比較してズレを直す。

- [ ] **Step 4: `docs/coding-standards.md` にも 1 節追記**

`docs/coding-standards.md` の任意の適切な位置（"命名規則" の後など）に以下を追加:

```markdown
## 新規リポジトリ追加時の main ブランチ保護

`terraform/modules/repository` を呼ぶだけで標準 `main` 保護が自動適用される。保護不要 repo は `disable_default_main_protection = true` を明示すること。詳細は [terraform-patterns.md](./terraform-patterns.md#標準-main-ブランチ保護opt-out-デフォルト)。
```

- [ ] **Step 5: markdown リントをローカルで通す**

```bash
prek run markdownlint-cli2 --files docs/terraform-patterns.md docs/coding-standards.md
```

Expected: Pass。失敗したらリンターが修正してくれるのでその結果を受け入れる。

- [ ] **Step 6: コミット**

```bash
git add docs/terraform-patterns.md docs/coding-standards.md
git commit -m "docs: 標準 main ブランチ保護（opt-out デフォルト）を追記"
```

---

## Task 8: push + PR 作成

- [ ] **Step 1: 最終状態を確認**

```bash
git log --oneline origin/main..HEAD
git status
```

Expected:

- `git log`: このプランで作ったコミットが 7 件程度並ぶ（Task 1-7 + 最初の spec 追加）
- `git status`: clean

- [ ] **Step 2: リモートへ push**

```bash
git push -u origin feat/main-branch-protection-ruleset
```

- [ ] **Step 3: PR を作成**

```bash
gh pr create --title "feat: 標準 main ブランチ保護を opt-out デフォルトで内蔵" --body "$(cat <<'EOF'
## Summary

- モジュール `terraform/modules/repository` に `github_repository_ruleset.default_main_protection` を追加
- opt-out フラグ `disable_default_main_protection`（デフォルト `false`）と所有者 bypass フラグ `default_main_protection_owner_bypass`（デフォルト `true`）を追加
- `terraform-github` 自身を state mv で新デフォルトに移行（approvals 1→0、status checks を workflow-result のみに集約）
- archived 3 件（`local-workspace-provisioning` / `obsidian-vault-old` / `setup-develop-environments`）を `disable_default_main_protection = true` + `visibility = "private"` 化
- docs を更新

詳細は `docs/superpowers/specs/2026-04-18-main-branch-protection-design.md` と `docs/superpowers/plans/2026-04-18-main-branch-protection.md` を参照。

## Test plan

- [x] `terraform validate` 成功（モジュール変更後）
- [x] `terraform plan` が期待差分のみを出す（destroy+create は無い）
- [x] `terraform apply` 成功（terraform-github self）
- [x] GitHub UI で `main` ruleset が意図通り（approvals 0 / status checks workflow-result / bypass PR のみ）
- [x] archived 3 件の visibility が private になっている
- [ ] CI がパス

## Follow-ups (別 PR)

- PR2: 影響小の 5 repo（`tqer39`, `time-capsule`, `boilerplate-base`, `boilerplate-saas`, `obsidian-vault`）
- PR3+: 残り 22 repo を 5-10 件ずつ

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 4: PR URL をユーザーに共有**

Expected: PR URL（例: `https://github.com/tqer39/terraform-github/pull/XXXX`）が出力される。

---

## Verification（全体）

PR 作成後、以下が満たされていること:

1. CI（`.github/workflows/`）が pass
2. `terraform-github` repo の GitHub Rulesets 画面に `main` ruleset が 1 つあり:
   - Enforcement: Active
   - Target: Default branch
   - Restrict deletions / Block force pushes / Require linear history
   - Require PR before merging (required approvals = 0, dismiss stale reviews = on, thread resolution = on)
   - Require status checks (workflow-result, strict = off)
   - Bypass actors: Repository admin (Pull request)
3. archived 3 件の visibility が private に（対象 repo のみ）
4. `main` ブランチへの直 push を試すと拒否される（手動確認は任意）

## Follow-ups（本プランのスコープ外）

- **PR2 / PR3+**: 残り 27 repo の移行（`tqer39` など）。本プランと同じ Task 4 + Task 5 のパターンを 1 repo ずつ適用する。別プランを書き起こす。
- **移行スクリプト化**: 残り repo 数が多い場合、`scripts/migrate-default-main-protection.sh` を作って `for repo in ... ; do cd ... ; terraform state mv ...; done` を自動化。本プランでは手動で進める。
- **新規 repo テンプレート更新**: `boilerplate-base` 系で新デフォルトが自動適用されるテンプレートになっているか確認（本プランの範囲外）。
