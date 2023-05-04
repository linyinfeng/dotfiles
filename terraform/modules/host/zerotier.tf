variable "zerotier_network_id" {
  type = string
}

resource "zerotier_identity" "host" {}

resource "zerotier_member" "host" {
  name                    = var.name
  member_id               = zerotier_identity.host.id
  network_id              = var.zerotier_network_id
  hidden                  = false
  allow_ethernet_bridging = true
  no_auto_assign_ips      = false
}

output "zerotier_id" {
  value = zerotier_identity.host.id
}
output "zerotier_public_key" {
  value = zerotier_identity.host.public_key
}
output "zerotier_private_key" {
  value     = zerotier_identity.host.private_key
  sensitive = true
}
