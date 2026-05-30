output "api_url" {
  description = "API endpoint URL"
  value = "http://localhost:${var.app_port}"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value = "http://localhost:${var.grafana_port}"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value = "http://localhost:${var.prometheus_port}"
}

output "nginx_url" {
  description = "NGINX reverse proxy URL"
  value = "http://localhost:${var.nginx_port}"
}

output "network_name" {
  description = "Docker network name"
  value = docker_network.devops_net.name
}
