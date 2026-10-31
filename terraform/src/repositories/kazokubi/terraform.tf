terraform {
  required_version = "1.16.6"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
  backend "s3" {
    bucket = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    # 既存 state の保存先を引き継ぎ、root の改名で空の state を作らない。
    key     = "terraform-github/repositories/family-schedule.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
