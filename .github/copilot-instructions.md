## コンテキスト指示書

### このリポジトリの概要

このリポジトリは、TerraformとGitHub Actionsを使って、複数のGitHubリポジトリの作成・管理・保護を自動化するIaC（Infrastructure as Code）プロジェクトです。

### ディレクトリ構成と役割

- `terraform/modules/repository/`：GitHubリポジトリ管理のためのTerraformモジュール群。リポジトリ作成、ブランチ保護、Actions権限などを定義。
- `terraform/src/repository/`：各GitHubリポジトリごとのTerraform設定ファイル。module呼び出しで個別リポジトリを管理。
- `scripts/`：GitHubリポジトリに共通シークレットを設定するシェルスクリプトなど。
- `docs/`：日本語ドキュメント。

### 主要なTerraformリソース

- `github_repository`：GitHubリポジトリの作成・設定
- `github_branch_protection`：ブランチ保護ルールの設定
- `github_actions_repository_permissions`：GitHub Actionsの実行権限制御
- `github_branch_default`：デフォルトブランチの設定
- `github_branch`：main以外のブランチ作成

### 変数・パラメータ例

- `repository`：リポジトリ名
- `description`：説明文
- `topics`：トピック（タグ）
- `branches_to_protect`：保護対象ブランチとルール
- `github_token`：認証用トークン

### 生成コードの注意点

- 既存のモジュールや変数名、リソース名を流用すること
- `terraform/modules/repository/` 配下のモジュール設計に従うこと
- `terraform/src/repository/` 配下の各ファイルは、個別リポジトリのmodule呼び出しであること
- ブランチ保護やActions権限など、セキュリティ設定も忘れずに

### 参考

- 詳細は`docs/README.ja.md`や`terraform/modules/repository/variables.tf`を参照

---

この内容をもとに、Copilotはリポジトリの構成や設計思想を理解し、Terraformコードやシェルスクリプトの提案時に適切なコンテキストを考慮してください。
