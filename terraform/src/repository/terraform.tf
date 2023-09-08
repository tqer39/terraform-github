terraform {
  required_version = "1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.16.1"
    }
    github = {
      source  = "integrations/github"
      version = "5.34.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "terraform-github/terraform/src/repository.tfstate"
    region  = "ap-northeast-1"
  }
}
