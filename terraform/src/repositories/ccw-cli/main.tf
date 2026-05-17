module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "ccw-cli"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  topics              = ["claude-code", "cli", "git-worktree", "bash"]
  description         = "Claude Code worktree launcher with picker & superpowers preamble"
  visibility          = "public"
}
