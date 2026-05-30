resource "docker_network" "this" {
  name = var.network_name
  driver = "bridge"

  ipam_config {
    subnet = var.subnet
  }
}
