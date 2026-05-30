variable "network_name" {
  description = "Docker network name"
  type = string
}

variable "subnet" {
  description = "Network subnet CIDR"
  type = string
  default = "172.20.0.0/16"
}
