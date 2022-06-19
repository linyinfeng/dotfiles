variable "zerotier_network_id" {
  type = string
}

variable "zerotier_ip_assignments" {
  type = list(string)
}

resource "zerotier_identity" "host" {}

resource "zerotier_member" "host" {
  name                    = var.name
  member_id               = zerotier_identity.host.id
  network_id              = var.zerotier_network_id
  hidden                  = false
  allow_ethernet_bridging = true
  no_auto_assign_ips      = false
  ip_assignments          = var.zerotier_ip_assignments
}

output "zerotier_public_key" {
  value = zerotier_identity.host.public_key
}
output "zerotier_private_key" {
  value     = zerotier_identity.host.private_key
  sensitive = true
}
