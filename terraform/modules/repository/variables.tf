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

variable "has_wiki" {
  type        = bool
  description = "(Optional) Set to true to enable the GitHub Wiki features on the repository."
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
  type        = list(string)
  description = "(Optional) The list of topics of the repository."
  default     = []
}

variable "vulnerability_alerts" {
  type        = bool
  description = "(Optional) - Set to true to enable security alerts for vulnerable dependencies. Enabling requires alerts to be enabled on the owner level. (Note for importing: GitHub enables the alerts on public repos but disables them on private repos by default.) See GitHub Documentation for details. Note that vulnerability alerts have not been successfully tested on any GitHub Enterprise instance and may be unavailable in those settings."
  default     = false
}

variable "branches_to_protect" {
  type        = any
  default     = {}
  description = "github_branch_protection variables. See https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_protection#argument-reference"
}
