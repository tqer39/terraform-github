module "this" {
  source       = "../../../modules/repository"
  github_token = var.github_token

  repository          = "learn-kubernetes"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "public"
  description         = "Kubernetes learning playground: manifests, kubectl exercises, and cluster experiments."
  topics = [
    "kubernetes",
    "k8s",
    "learning",
    "playground",
  ]
}
