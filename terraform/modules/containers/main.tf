resource "docker_volume" "postgres" {
  name = "postgres-data-${var.environment}"
}

resource "docker_volume" "redis" {
  name = "redis-data-${var.environment}"
}

resource "docker_volume" "prometheus" {
  name = "prometheus-data-${var.environment}"
}

resource "docker_volume" "grafana" {
  name = "grafana-data-${var.environment}"
}

resource "docker_container" "postgres" {
  name  = "devops-postgres-${var.environment}"
  image = "postgres:16-alpine"

  networks_advanced { name = var.network_id }

  env = [
    "POSTGRES_DB=devops_platform",
    "POSTGRES_USER=devops",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ]

  volumes {
    volume_name    = docker_volume.postgres.name
    container_path = "/var/lib/postgresql/data"
  }

  restart = "unless-stopped"

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U devops -d devops_platform"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

resource "docker_container" "redis" {
  name  = "devops-redis-${var.environment}"
  image = "redis:7-alpine"

  networks_advanced { name = var.network_id }

  command = ["redis-server", "--appendonly", "yes"]

  volumes {
    volume_name    = docker_volume.redis.name
    container_path = "/data"
  }

  restart = "unless-stopped"

  healthcheck {
    test     = ["CMD", "redis-cli", "ping"]
    interval = "30s"
    timeout  = "5s"
    retries  = 3
  }
}

resource "docker_container" "api" {
  name  = "devops-api-${var.environment}"
  image = var.api_image

  networks_advanced { name = var.network_id }

  ports {
    internal = 3000
    external = var.api_port
  }

  env = [
    "NODE_ENV=${var.environment}",
    "PORT=3000",
    "POSTGRES_HOST=devops-postgres-${var.environment}",
    "POSTGRES_DB=devops_platform",
    "POSTGRES_USER=devops",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "REDIS_HOST=devops-redis-${var.environment}",
  ]

  restart = "unless-stopped"

  depends_on = [docker_container.postgres, docker_container.redis]
}

resource "docker_container" "prometheus" {
  name  = "devops-prometheus-${var.environment}"
  image = "prom/prometheus:v2.51.0"

  networks_advanced { name = var.network_id }

  volumes {
    volume_name    = docker_volume.prometheus.name
    container_path = "/prometheus"
  }

  volumes {
    host_path      = abspath("${path.module}/../../../monitoring/prometheus/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  command = ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus"]
  restart = "unless-stopped"
}

resource "docker_container" "grafana" {
  name  = "devops-grafana-${var.environment}"
  image = "grafana/grafana:10.4.0"

  networks_advanced { name = var.network_id }

  ports {
    internal = 3000
    external = 3030
  }

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
  ]

  volumes {
    volume_name    = docker_volume.grafana.name
    container_path = "/var/lib/grafana"
  }

  restart    = "unless-stopped"
  depends_on = [docker_container.prometheus]
}
