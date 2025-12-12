terraform {
  required_version = "1.14.2"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.9.0"
    }
  }
}
