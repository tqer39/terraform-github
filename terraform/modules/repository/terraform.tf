terraform {
  required_version = "1.15.5"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.12.1"
    }
  }
}
