terraform {
  required_version = "1.4.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.0"
    }
    github = {
      source  = "integrations/github"
      version = "5.29.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "terraform-github/terraform/src/repository.tfstate"
    region  = "ap-northeast-1"
  }
}
