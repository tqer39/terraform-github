# Copilot Instructions

- 返信・レビューはすべて日本語で、簡潔かつ要点優先で行うこと。
- 変更範囲に集中し、不要なリファクタ提案や無関係な指摘は避けること。
- リスクや不具合の可能性を優先して指摘し、必要な修正方針を短く提示すること。
- Terraform 変更がある場合は `terraform fmt -recursive` → `terraform -chdir=terraform/src/repository validate` → `terraform -chdir=terraform/src/repository plan` の実行/確認を促すこと。
- 破壊的変更や apply が必要な場合は必ず注意喚起すること。
