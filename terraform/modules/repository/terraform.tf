terraform {
  required_version = "1.12.1"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
  }
}
