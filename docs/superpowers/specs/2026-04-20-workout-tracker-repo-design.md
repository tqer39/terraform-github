# workout-tracker リポジトリ追加設計

## 概要

筋トレメニューの登録と実施記録を行う iOS アプリ (`tqer39/workout-tracker`) の GitHub リポジトリを Terraform で管理する。既存の `terraform/src/repositories/<repo>/` パターンに従い、1 リポジトリ 1 ディレクトリ構成で追加する。

## 要件

| 項目 | 値 |
| --- | --- |
| リポジトリ名 | `workout-tracker` |
| owner | `tqer39` |
| visibility | Public |
| description | `iOS app for registering workout menus and recording training sessions, built with Swift and SwiftUI.` |
| default_branch | `main` |
| topics | `swift`, `swiftui`, `ios`, `workout`, `fitness`, `swiftdata`, `training-log` |
| template | なし（空リポジトリから Xcode で作成） |
| enable_owner_bypass | `true` |
| configure_actions_permissions | 指定しない（モジュールデフォルト） |
| main ブランチ保護 | モジュールデフォルト（force push 禁止・削除禁止・PR 必須・linear history・`workflow-result` 必須・承認 0・所有者 bypass） |

## アプリ仕様（参考・今回のリポジトリ管理スコープ外）

- プラットフォーム: iOS（Swift + SwiftUI）
- バックエンド: なし。端末ローカルで完結（SwiftData または Core Data を採用）
- クラウド同期は現状スコープ外

本 spec は Terraform による GitHub リポジトリ管理のみを対象とし、アプリ実装は別プロジェクト（新リポジトリ内）で扱う。

## ファイル構成

既存 repo の定型に合わせ、`terraform/src/repositories/workout-tracker/` 配下に以下の 5 ファイルを新規追加する。

- `main.tf`: `../../../modules/repository` を呼び出す
- `variables.tf`: `github_token` 変数定義
- `providers.tf`: `github` プロバイダ設定
- `terraform.tf`: required_version / required_providers / S3 backend（key は `terraform-github/repositories/workout-tracker.tfstate`）
- `outputs.tf`: 現時点で出力なし（プレースホルダーコメント）

`.terraform.lock.hcl` は `terraform init` によって自動生成されるため、手書きしない。

## main.tf の主要パラメータ

```hcl
module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository     = "workout-tracker"
  owner          = "tqer39"
  default_branch = "main"
  enable_owner_bypass = true
  description    = "iOS app for registering workout menus and recording training sessions, built with Swift and SwiftUI."
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

`disable_default_main_protection` は指定しない（標準保護を新規段階から適用）。`branch_rulesets` ブロックも書かず、モジュールデフォルトに委ねる。`template_*` も指定しない。

## 検証

- `just fmt` で HCL フォーマット
- `just validate` で構文検証
- `just plan` で新規 repo が作成計画に載ることを確認（`workout-tracker` の `github_repository` が add で表示される）

## 非スコープ

- iOS アプリ本体の実装
- CI/CD ワークフロー（後続 PR で追加）
- Xcode プロジェクト初期化
