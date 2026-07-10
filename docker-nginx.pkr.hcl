packer {
  required_plugins {
    docker = {
      version = ">= 1.0.9"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "image_name" {
  type    = string
  default = "nginx-custom"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

# Image de base : Nginx officielle (Alpine, légère)
source "docker" "nginx-custom" {
  image  = "nginx:stable-alpine"
  commit = true

  changes = [
    "EXPOSE 80",
    "WORKDIR /usr/share/nginx/html",
    "ENTRYPOINT [\"/docker-entrypoint.sh\"]",
    "CMD [\"nginx\", \"-g\", \"daemon off;\"]"
  ]
}

build {
  name    = "nginx-custom"
  sources = ["source.docker.nginx-custom"]

  # On embarque le index.html présent à la racine du repo dans l'image
  provisioner "file" {
    source      = "../index.html"
    destination = "/usr/share/nginx/html/index.html"
  }

  post-processor "docker-tag" {
    repository = var.image_name
    tags        = [var.image_tag]
  }
}
