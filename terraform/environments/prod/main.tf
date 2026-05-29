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

module "network" {
  source       = "../../modules/network"
  network_name = "devops-net-prod"
  subnet       = "172.22.0.0/16"
}

module "containers" {
  source                 = "../../modules/containers"
  network_id             = module.network.network_id
  environment            = "prod"
  api_image              = var.api_image
  api_port               = var.api_port
  postgres_password      = var.postgres_password
  grafana_admin_password = var.grafana_admin_password
}
