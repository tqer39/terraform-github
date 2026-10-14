resource "github_actions_variable" "usage_monitor_enabled" {
  repository    = "kazokubi"
  variable_name = "USAGE_MONITOR_ENABLED"
  value         = "true"
  depends_on    = [module.this]
}
