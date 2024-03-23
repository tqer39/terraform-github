# terraform-github

## 概要

このリポジトリはTerraformとGitHub Actionsを使用してAWS上にインフラストラクチャをデプロイするためのものです。Terraformはインフラストラクチャのコード化を可能にし、GitHub ActionsはCI/CDパイプラインを自動化します。

## デプロイフロー

1. GitHub Actionsのワークフローがトリガーされます（例えば、プルリクエストがマージされたとき）。
2. [`set-matrix`](.github/actions/set-matrix/action.yml)アクションが実行され、Terraformの実行対象ディレクトリのリストを作成します。
3. [`setup-terraform`](.github/actions/setup-terraform/action.yml)アクションが実行され、Terraformをセットアップします。
4. [`terraform-plan`](.github/actions/terraform-plan/action.yml)アクションが実行され、Terraformの計画が作成されます。
5. [`terraform-apply`](.github/actions/terraform-apply/action.yml)アクションが実行され、Terraformの計画が適用されます。

```mermaid
graph LR
  A[GitHub Actions Trigger] --> B[setup-terraform]
  B --> C[terraform-plan]
  C --> D[terraform-apply]
  D --> E[Infrastructure is deployed]
  E --> F[Changes are reflected in the GitHub repository]
```

## ディレクトリとファイルの役割

- `.editorconfig`: エディタの設定を統一するためのファイルです。
- `.github/`: GitHubの設定ファイルやGitHub Actionsのワークフローが格納されています。
- `.gitignore`: Gitで追跡しないファイルやディレクトリを指定するためのファイルです。
- `.markdownlint.json`: MarkdownファイルのLint設定を行うためのファイルです。
- `.pre-commit-config.yaml`: pre-commitフックの設定を行うためのファイルです。
- `.textlintignore`: textlintで無視するファイルやディレクトリを指定するためのファイルです。
- `.textlintrc`: textlintの設定を行うためのファイルです。
- `.tool-versions`: 使用するツールのバージョンを指定するためのファイルです。
- `.vscode/`: Visual Studio Codeの設定を行うためのディレクトリです。
- `.yamllint`: YAMLファイルのLint設定を行うためのファイルです。
- `cspell.json`: cspell（スペルチェックツール）の設定を行うためのファイルです。
- `README.md`: リポジトリの説明を記述するためのファイルです。
- `renovate.json`: Renovate（依存関係の更新ツール）の設定を行うためのファイルです。
- `terraform/`: Terraformの設定ファイルやモジュールが格納されています。
