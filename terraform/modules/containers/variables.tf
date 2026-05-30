variable "network_id" {
  description = "Docker network ID to attach containers"
  type = string
}

variable "environment" {
  description = "Deployment environment"
  type = string
}

variable "api_image" {
  description = "API Docker image"
  type = string
}

variable "api_port" {
  description = "Host port for API"
  type = number
  default = 3000
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type = string
  sensitive = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type = string
  sensitive = true
}
