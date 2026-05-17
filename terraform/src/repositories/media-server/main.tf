module "this" {
  source              = "../../../modules/repository"
  github_token        = var.github_token
  repository          = "media-server"
  owner               = "tqer39"
  default_branch      = "main"
  enable_owner_bypass = true
  visibility          = "private"
  topics              = ["docker", "docker-compose", "ubuntu-server", "jellyfin", "komga", "audiobookshelf", "homelab"]
  description         = "Ubuntu Server media stack with Docker Compose for LAN streaming (Jellyfin, Komga, Audiobookshelf)."
}
