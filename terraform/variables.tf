variable "app_image" {
  description = "Docker image for the API"
  type        = string
  default     = "devops-local-platform-api:latest"
}

variable "app_port" {
  description = "Host port for the API"
  type        = number
  default     = 3000
}

variable "grafana_port" {
  description = "Host port for Grafana"
  type        = number
  default     = 3001
}

variable "prometheus_port" {
  description = "Host port for Prometheus"
  type        = number
  default     = 9090
}

variable "nginx_port" {
  description = "Host port for NGINX"
  type        = number
  default     = 80
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}
