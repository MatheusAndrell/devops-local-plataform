variable "api_image" {
  type = string
  default = "devops-local-platform-api:stable"
}

variable "api_port" {
  type = number
  default = 3000
}

variable "postgres_password" {
  type = string
  sensitive = true
}

variable "grafana_admin_password" {
  type = string
  sensitive = true
}
