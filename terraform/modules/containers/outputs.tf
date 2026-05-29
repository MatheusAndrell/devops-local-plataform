output "api_container_id" {
  value = docker_container.api.id
}

output "postgres_container_id" {
  value = docker_container.postgres.id
}

output "grafana_container_id" {
  value = docker_container.grafana.id
}
