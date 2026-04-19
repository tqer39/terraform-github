module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "workout-tracker"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  description         = "iOS app for registering workout menus and recording training sessions, built with Swift and SwiftUI."
  topics = [
    "swift",
    "swiftui",
    "ios",
    "workout",
    "fitness",
    "swiftdata",
    "training-log",
  ]
}
