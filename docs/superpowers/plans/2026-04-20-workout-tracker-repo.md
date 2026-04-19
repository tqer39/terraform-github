# workout-tracker リポジトリ追加 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新規リポジトリ `tqer39/workout-tracker`（iOS 筋トレ記録アプリ）を Terraform で管理できるようにする。

**Architecture:** `terraform/src/repositories/workout-tracker/` ディレクトリを新設し、既存 `edu-quest` / `xtrade` と同じ 5 ファイル構成（main.tf / variables.tf / providers.tf / terraform.tf / outputs.tf）で `../../../modules/repository` を呼び出す。モジュールデフォルトの main ブランチ保護を適用する（`disable_default_main_protection` は指定しない）。

**Tech Stack:** Terraform 1.14.8, integrations/github 6.11.1, S3 backend（ap-northeast-1）, lefthook/pre-commit, cspell, textlint, markdownlint, tflint

**Spec:** `docs/superpowers/specs/2026-04-20-workout-tracker-repo-design.md`

---

## File Structure

新規作成:

- `terraform/src/repositories/workout-tracker/main.tf` — モジュール呼び出し（リポジトリ本体定義）
- `terraform/src/repositories/workout-tracker/variables.tf` — `github_token` 入力変数
- `terraform/src/repositories/workout-tracker/providers.tf` — GitHub プロバイダ設定
- `terraform/src/repositories/workout-tracker/terraform.tf` — required_version / required_providers / S3 backend
- `terraform/src/repositories/workout-tracker/outputs.tf` — 現状出力なし（コメントのみ）

`.terraform.lock.hcl` は `terraform init` で自動生成されるため手書きしない。

変更なし（既存ワークフローが `terraform/src/repositories/*` をマトリックスで自動検出するため、CI 側の変更は不要）。

---

## Task 1: terraform.tf を作成

**Files:**

- Create: `terraform/src/repositories/workout-tracker/terraform.tf`

- [ ] **Step 1: ディレクトリとファイルを作成**

```hcl
terraform {
  required_version = "1.14.8"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    key     = "terraform-github/repositories/workout-tracker.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
```

既存 `terraform/src/repositories/edu-quest/terraform.tf` と同一構造、`key` のみ `workout-tracker.tfstate` に差し替え。

---

## Task 2: providers.tf を作成

**Files:**

- Create: `terraform/src/repositories/workout-tracker/providers.tf`

- [ ] **Step 1: ファイル作成**

```hcl
provider "github" {
  owner = "tqer39"
  token = var.github_token
}
```

---

## Task 3: variables.tf を作成

**Files:**

- Create: `terraform/src/repositories/workout-tracker/variables.tf`

- [ ] **Step 1: ファイル作成**

```hcl
variable "github_token" {
  type        = string
  description = "GitHub token"
  sensitive   = true
}
```

---

## Task 4: outputs.tf を作成

**Files:**

- Create: `terraform/src/repositories/workout-tracker/outputs.tf`

- [ ] **Step 1: ファイル作成**

```hcl
# Outputs can be added here if needed
```

---

## Task 5: main.tf を作成

**Files:**

- Create: `terraform/src/repositories/workout-tracker/main.tf`

- [ ] **Step 1: ファイル作成**

```hcl
module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "workout-tracker"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "iOS app for registering workout menus and recording training sessions, built with Swift and SwiftUI."
  topics = [
    "swift",
    "swiftui",
    "ios",
    "workout",
    "fitness",
    "swiftdata",
    "training-log",
  ]
}
```

設計原則:

- `disable_default_main_protection` は指定しない（新規 repo なのでモジュールデフォルトの main 保護を最初から適用）
- `branch_rulesets` ブロックも書かない（モジュールデフォルトに委ねる）
- `template_*` も指定しない（空リポジトリから Xcode で作成）
- `configure_actions_permissions` も指定しない（モジュールデフォルト）

---

## Task 6: フォーマット

- [ ] **Step 1: terraform fmt**

Run: `just fmt`
Expected: 差分なし（すでに正しい形式で書いているため）、もしくは最小限の整形差分のみ

---

## Task 7: Terraform 初期化と検証

**Files:**

- Auto-create: `terraform/src/repositories/workout-tracker/.terraform.lock.hcl`

- [ ] **Step 1: terraform init**

Run: `cd terraform/src/repositories/workout-tracker && terraform init`
Expected: `Terraform has been successfully initialized!` と表示され、`.terraform.lock.hcl` が生成される

- [ ] **Step 2: terraform validate**

Run: `cd terraform/src/repositories/workout-tracker && terraform validate`
Expected: `Success! The configuration is valid.`

- [ ] **Step 3: terraform plan（可能であれば）**

Run: `cd terraform/src/repositories/workout-tracker && terraform plan`
Expected: `module.this.github_repository.this` を含む複数リソースが `will be created` として表示される。
Note: AWS 認証 / GITHUB_TOKEN が無い場合はこの手順をスキップし、コメントで「ローカル環境に認証情報がないため CI の plan に委ねる」と記録する。

---

## Task 8: pre-commit / lefthook での検証

- [ ] **Step 1: lefthook run**

Run: `just lint`
Expected: すべて ✅（`terraform-fmt`, `cspell`, `markdownlint`, `textlint`, `betterleaks`, `yamllint`, `actionlint` 等）

cspell が `swiftui` / `swiftdata` 等について警告した場合は `.cspell/project-words.txt` に追加（spec 執筆時に追加済みなので本来不要）。

---

## Task 9: コミット

- [ ] **Step 1: 追加ファイルをステージング**

Run:

```bash
git add terraform/src/repositories/workout-tracker/main.tf \
        terraform/src/repositories/workout-tracker/variables.tf \
        terraform/src/repositories/workout-tracker/providers.tf \
        terraform/src/repositories/workout-tracker/terraform.tf \
        terraform/src/repositories/workout-tracker/outputs.tf \
        terraform/src/repositories/workout-tracker/.terraform.lock.hcl
```

- [ ] **Step 2: コミット**

Run:

```bash
git commit -m "$(cat <<'EOF'
✨ workout-tracker リポジトリを Terraform 管理に追加

iOS 筋トレ記録アプリ用の GitHub リポジトリを新規追加。
Swift + SwiftUI 構成、ローカル完結（SwiftData/CoreData）を想定。
モジュールデフォルトの main ブランチ保護を適用。
EOF
)"
```

Expected: pre-commit フックが全項目 ✅ を返し commit 成功。

---

## Task 10: ブランチ push と PR 作成

- [ ] **Step 1: push**

Run: `git push -u origin <current-branch>`
Expected: push 成功、CI 側で `terraform-github.yml` の matrix が `workout-tracker` を検出して plan を実行

- [ ] **Step 2: PR 作成**

Run: `gh pr create --title "✨ workout-tracker リポジトリを Terraform 管理に追加" --body "..."`
Body には以下を含める:

- 概要: iOS 筋トレ記録アプリ用リポジトリ追加
- 設計ドキュメントへのリンク: `docs/superpowers/specs/2026-04-20-workout-tracker-repo-design.md`
- スタック: Swift + SwiftUI, ローカル完結
- CI の `terraform plan` 出力が `github_repository workout-tracker` の create プランを含むことを確認

Expected: PR URL が返ってくる。CI の `workflow-result` が緑になったらマージ可能。

---

## Self-Review Checklist（書き手が記入済み）

- [x] Spec の「ファイル構成」「main.tf の主要パラメータ」「検証」要件を Task 1-8 が網羅
- [x] Placeholder（TBD / TODO / "あとで"）無し
- [x] 型・パラメータ名一貫性（`workout-tracker` / `training-log` / `swiftdata` が全 Task で一致）
- [x] 各 Task は 2-5 分で完了可能な粒度
