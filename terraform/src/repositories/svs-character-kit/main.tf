module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token
  repository   = "svs-character-kit"
  owner        = "tqer39"
  description  = "サマバケ！すくらんぶるのキャラクター生成キット"
  visibility   = "private"
}

import {
  to = module.this.github_repository.this[0]
  id = "svs-character-kit"
}
