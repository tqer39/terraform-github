terraform {
  required_version = "1.14.5"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    key     = "terraform-github/repositories/boilerplate-saas.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
