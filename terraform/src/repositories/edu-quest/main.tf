module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "edu-quest"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "Educational platform for elementary students featuring multiple learning quests (Math, Kanji, Clock) built with Hono SSR on Cloudflare Workers."
  topics = [
    "cloudflare-workers",
    "hono",
    "ssr",
    "elementary-math",
    "education",
    "pnpm",
    "terraform",
    "monorepo",
    "drizzle-orm",
    "wrangler",
  ]
  configure_actions_permissions = false

  template_owner                = "tqer39"
  template_repository           = "boilerplate-base"
  template_include_all_branches = false
}
