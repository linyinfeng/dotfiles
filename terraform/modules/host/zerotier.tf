variable "zerotier_network_id" {
    type = string
}

resource "zerotier_identity" "host" { }

resource "zerotier_member" "host" {
  name                    = var.name
  member_id               = zerotier_identity.identity.id
  network_id              = var.zerotier_network_id
  hidden                  = false
  allow_ethernet_bridging = true
  no_auto_assign_ips      = false
}
