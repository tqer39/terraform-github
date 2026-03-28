terraform {
  required_version = "1.14.8"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }
  }
}
