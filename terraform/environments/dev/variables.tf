variable "api_image" {
  type = string
  default = "devops-local-platform-api:latest"
}

variable "api_port" {
  type = number
  default = 3000
}

variable "postgres_password" {
  type = string
  sensitive = true
  default = "devops123"
}

variable "grafana_admin_password" {
  type = string
  sensitive = true
  default = "admin123"
}
