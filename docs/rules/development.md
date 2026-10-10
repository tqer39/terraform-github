# 開発作業の規約

- 回答と Markdown 文書は日本語にする。言語別の重複文書は作らない
- 依頼されたことだけを行う。それ以上もそれ以下もしない
- ファイルの新規作成は最小限に。既存ファイルの編集を優先する
- 変更前に既存コードを読み、パターンを理解する
- **Conventional Commits** に準拠（`feat:`, `fix:`, `chore:`, `refactor:`）
- 変更時は必ず検証: `mise run tf:validate && mise run tf:plan`
- 新規 repo 追加時に `disable_default_main_protection` を指定しなければ、モジュールデフォルトで標準 main 保護（force push 禁止 / 削除禁止 / PR 必須 / linear history / `workflow-result` 必須 / 承認 0 / 所有者 bypass）が自動適用される
