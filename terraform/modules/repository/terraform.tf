terraform {
  required_version = "1.15.2"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.12.1"
    }
  }
}
