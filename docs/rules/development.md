# 開発作業の規約

- 回答と Markdown 文書は日本語にする。言語別の重複文書は作らない
- 依頼されたことだけを行う。それ以上もそれ以下もしない
- ファイルの新規作成は最小限に。既存ファイルの編集を優先する
- 変更前に既存コードを読み、パターンを理解する
- **Conventional Commits** に準拠（`feat:`, `fix:`, `chore:`, `refactor:`）
- Terraform 設定の変更時はローカルで `mise run tf:validate <repo-name>` を実行し（省略すると `terraform-github` だけを検証する）、plan はローカルまたは PR の CI で確認する。ローカル plan に新しい認証が必要な場合は、下記の PR 手順に従う。未作成のリポジトリは CI で plan できないため、下記の実行範囲に従う
- 新規 repo 追加時に `disable_default_main_protection` を指定しなければ、モジュールデフォルトで標準 main 保護（force push 禁止 / 削除禁止 / PR 必須 / linear history / `workflow-result` 必須 / 承認 0 / 所有者 bypass）が自動適用される

## リポジトリ作成依頼の実行範囲

- 「リポジトリを作成して」「リポジトリを追加して」という依頼は、Terraform 定義（作成済みリポジトリを取り込む `import` ブロックを含む）の追加、ローカル検証、コミット、push、PR 作成までを意味する。CI の App installation token は個人アカウントにリポジトリを作成できないため、GitHub 上の作成と App のインストール先への追加は、ユーザーが行うか、明示的に依頼された場合に行う
- この依頼だけを根拠に、ローカルの `terraform apply`、GitHub API / CLI による直接作成、PR のマージ、手動 apply ワークフローの起動を行わない。これらはユーザーが対象の操作を明示的に依頼した場合に限る
- PR 作成のために AWS SSO ログインや `aws-vault exec` を開始しない。ローカル検証は `terraform init -backend=false` と validate を使い、AWS 認証が必要な plan は PR の CI に任せる。リポジトリが未作成の間は App トークンを発行できず PR の CI が失敗するため、作成後に再実行して plan を確認する
- ローカル plan を省略した場合は、PR に理由と CI で確認する旨を記載する。plan 未実施を検証成功として扱わない
- 完了報告は「PR を作成した」と「GitHub リポジトリが作成された」を区別する。作成を確認していないリポジトリを作成済みと報告しない。未作成の場合は、CI が失敗する理由と、作成と CI の再実行が残っていることを報告する
