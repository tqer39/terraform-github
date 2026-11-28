variable "github_token" {
  type        = string
  description = "GitHub token"
  sensitive   = true
}

variable "owner" {
  type        = string
  description = "(Optional) The GitHub organization or user account that will own the repository."
  default     = null
}

variable "default_branch" {
  type        = string
  description = "(Required) The repository branch to create."
  default     = "main"
}

variable "repository" {
  type        = string
  description = "(Required) The GitHub repository name."
}

variable "description" {
  type        = string
  description = "(Optional) A description of the repository."
  default     = "A repository created by Terraform."
}

variable "visibility" {
  type        = string
  description = "(Optional) Can be `public` or `private`. If your organization is associated with an enterprise account using GitHub Enterprise Cloud or GitHub Enterprise Server 2.20+, visibility can also be `internal`. The `visibility` parameter overrides the `private` parameter."
  default     = "public"
}

variable "has_issues" {
  type        = bool
  description = "(Optional) Set to `true` to enable the GitHub Issues features on the repository."
  default     = true
}

variable "has_wiki" {
  type        = bool
  description = "(Optional) Set to `true` to enable the GitHub Wiki features on the repository."
  default     = false
}

variable "has_projects" {
  type        = bool
  description = "(Optional) Set to `true` to enable the GitHub Projects features on the repository. Per the GitHub documentation when in an organization that has disabled repository projects it will default to `false` and will otherwise default to `true`. If you specify `true` when it has been disabled it will return an error."
  default     = false
}

variable "allow_auto_merge" {
  type        = bool
  description = "(Optional) Set to true to allow auto-merging pull requests on the repository."
  default     = true
}

variable "allow_update_branch" {
  type        = bool
  description = "(Optional) - Set to true to always suggest updating pull request branches."
  default     = true
}

variable "allow_merge_commit" {
  type        = bool
  description = "(Optional) Set to false to disable merge commits on the repository."
  default     = true
}

variable "allow_squash_merge" {
  type        = bool
  description = "(Optional) Set to false to disable squash merging on the repository."
  default     = true
}

variable "allow_rebase_merge" {
  type        = bool
  description = "(Optional) Set to false to disable rebase merging on the repository."
  default     = true
}

variable "squash_merge_commit_title" {
  type        = string
  description = "(Optional) Default squash merge commit title. Can be PR_TITLE or COMMIT_OR_PR_TITLE."
  default     = null
}

variable "squash_merge_commit_message" {
  type        = string
  description = "(Optional) Default squash merge commit message. Can be PR_BODY, COMMIT_MESSAGES, or BLANK."
  default     = null
}

variable "delete_branch_on_merge" {
  type        = bool
  description = "(Optional) Automatically delete head branch after a pull request is merged. Defaults to false."
  default     = true
}

variable "auto_init" {
  type        = bool
  description = "(Optional) Set to true to produce an initial commit in the repository."
  default     = true
}

variable "archived" {
  type        = bool
  description = "(Optional) Specifies if the repository should be archived. Defaults to false"
  default     = false
}

variable "topics" {
  description = "(Optional) The list of topics of the repository."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for topic in var.topics :
      can(regex("^[a-z0-9][a-z0-9-]{0,49}$", topic))
    ])
    error_message = "All topics must include only lowercase alphanumeric characters or hyphens, cannot start with a hyphen, and must be 50 characters or less."
  }
}

variable "vulnerability_alerts" {
  type        = bool
  description = "(Optional) - Set to true to enable security alerts for vulnerable dependencies. Enabling requires alerts to be enabled on the owner level. (Note for importing: GitHub enables the alerts on public repos but disables them on private repos by default.) See GitHub Documentation for details. Note that vulnerability alerts have not been successfully tested on any GitHub Enterprise instance and may be unavailable in those settings."
  default     = true
}

variable "secret_scanning" {
  type        = bool
  description = "(Optional) Whether secret scanning is enabled. Leave null to keep the current GitHub setting unmanaged. Must be set together with secret_scanning_push_protection."
  default     = null
}

variable "secret_scanning_push_protection" {
  type        = bool
  description = "(Optional) Whether secret scanning push protection is enabled. Leave null to keep the current GitHub setting unmanaged. Must be set together with secret_scanning."
  default     = null

  # provider は両方の現在値を state に読み込むため、片方だけ指定すると省いた側の削除差分が出る。
  validation {
    condition     = (var.secret_scanning == null) == (var.secret_scanning_push_protection == null)
    error_message = "secret_scanning and secret_scanning_push_protection must be set together or both left null."
  }
}

variable "branches_to_protect" {
  type        = any
  default     = {}
  description = "github_branch_protection variables. See https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_protection#argument-reference"
}

variable "configure_actions_permissions" {
  type        = bool
  description = "(Optional) Whether to configure GitHub Actions permissions for the repository. Set to false if the repository doesn't exist yet to avoid 404 errors during planning."
  default     = true
}

variable "actions_enabled" {
  type        = bool
  description = "(Optional) Whether GitHub Actions is enabled for the repository."
  default     = true
}

variable "allowed_actions" {
  type        = string
  description = "(Optional) The permissions policy that controls the actions that are allowed to run. Can be one of: `all`, `local_only`, or `selected`."
  default     = "all"
}

variable "sha_pinning_required" {
  type        = bool
  description = "(Optional) Whether actions must be pinned to a full-length commit SHA. Reusable workflows can still be referenced by tag. Leave null to keep the current GitHub setting unmanaged. Provider 6.13.0 does not send false, so changing true to false does not disable the setting."
  default     = null
}

variable "github_owned_allowed" {
  type        = bool
  description = "(Required) Whether GitHub-owned actions are allowed in the repository."
  default     = true
}

variable "patterns_allowed" {
  type        = list(string)
  description = "(Optional) Specifies a list of string-matching patterns to allow specific action(s). Wildcards, tags, and SHAs are allowed."
  default     = []
}

variable "verified_allowed" {
  type        = bool
  description = "(Optional) Whether actions in GitHub Marketplace from verified creators are allowed. Set to true to allow all GitHub Marketplace actions by verified creators."
  default     = true
}

variable "homepage_url" {
  type        = string
  description = "(Optional) URL of the repository homepage."
  default     = null
}

variable "branch_rulesets" {
  description = "A map of branch rulesets to apply to the repository."
  type        = any
  default     = {}
}

variable "enable_owner_bypass" {
  type        = bool
  description = "(Optional) Whether to allow repository admins to bypass branch protection rules."
  default     = false
}

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

variable "default_main_protection_bypass_app_ids" {
  type        = set(number)
  description = "標準 main 保護を常時 bypass できる GitHub App ID。Installation ID ではない。"
  default     = []

  validation {
    condition     = alltrue([for id in var.default_main_protection_bypass_app_ids : id > 0 && floor(id) == id])
    error_message = "GitHub App ID は正の整数で指定してください。"
  }
}

variable "default_main_protection_additional_required_checks" {
  type        = set(string)
  description = "標準 main 保護で `workflow-result` に加えて必須にするステータスチェックの context。対象のチェックがすべての PR で実行されるリポジトリにだけ指定する。"
  default     = []

  validation {
    condition     = alltrue([for context in var.default_main_protection_additional_required_checks : trimspace(context) != ""])
    error_message = "ステータスチェックの context は空にできません。"
  }
}

variable "is_template" {
  type        = bool
  description = "(Optional) Whether the repository is a template repository."
  default     = false
}

# Template repository settings (for creating a repo from a template)
variable "template_owner" {
  type        = string
  description = "(Optional) Owner of the template repository. Defaults to `owner` when null."
  default     = null
}

variable "template_repository" {
  type        = string
  description = "(Optional) Name of the template repository to generate from. When set, this repository will be created from that template."
  default     = null
}

variable "template_include_all_branches" {
  type        = bool
  description = "(Optional) When creating from template, include all branches instead of just the default branch."
  default     = false
}

variable "environments" {
  description = "A map of GitHub repository environments to create."
  type        = any
  default     = {}
}

# Fork repository settings
variable "fork" {
  type        = bool
  description = "(Optional) Set to true to create a fork of the source repository."
  default     = false
}

variable "source_owner" {
  type        = string
  description = "(Optional) Owner of the source repository to fork. Required when fork = true."
  default     = null
}

variable "source_repo" {
  type        = string
  description = "(Optional) Name of the source repository to fork. Required when fork = true."
  default     = null
}
