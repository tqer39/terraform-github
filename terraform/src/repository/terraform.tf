terraform {
  required_version = "1.12.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "terraform-github/terraform/src/repository.tfstate"
    region  = "ap-northeast-1"
  }
}
