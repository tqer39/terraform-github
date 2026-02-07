terraform {
  required_version = "1.14.4"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.11.0"
    }
  }
}
