terraform {
  required_version = ">= 1.6.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "devops_net" {
  name   = "devops-net-tf"
  driver = "bridge"
}

resource "docker_volume" "prometheus_data" {
  name = "prometheus-data-tf"
}

resource "docker_volume" "grafana_data" {
  name = "grafana-data-tf"
}

resource "docker_container" "api" {
  name  = "devops-api-tf"
  image = var.app_image

  networks_advanced {
    name = docker_network.devops_net.name
  }

  ports {
    internal = 3000
    external = var.app_port
  }

  env = [
    "NODE_ENV=production",
    "PORT=3000",
    "APP_VERSION=1.0.0",
  ]

  restart = "unless-stopped"

  healthcheck {
    test         = ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

resource "docker_container" "prometheus" {
  name  = "devops-prometheus-tf"
  image = "prom/prometheus:v2.51.0"

  networks_advanced {
    name = docker_network.devops_net.name
  }

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  volumes {
    host_path      = abspath("${path.module}/../monitoring/prometheus/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
  ]

  restart = "unless-stopped"
}

resource "docker_container" "grafana" {
  name  = "devops-grafana-tf"
  image = "grafana/grafana:10.4.0"

  networks_advanced {
    name = docker_network.devops_net.name
  }

  ports {
    internal = 3000
    external = var.grafana_port
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
  ]

  restart = "unless-stopped"

  depends_on = [docker_container.prometheus]
}

resource "docker_container" "nginx" {
  name  = "devops-nginx-tf"
  image = "nginx:1.25-alpine"

  networks_advanced {
    name = docker_network.devops_net.name
  }

  ports {
    internal = 80
    external = var.nginx_port
  }

  volumes {
    host_path      = abspath("${path.module}/../nginx/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }

  restart = "unless-stopped"

  depends_on = [docker_container.api]
}
