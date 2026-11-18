locals {
  vm_subnet = local.data.subnets.ostrich-incus
}

# IncusOS creates this bridge when it applies its default configuration.
import {
  to = incus_network.incusbr0
  id = "incusbr0"
}

resource "incus_network" "incusbr0" {
  name        = "incusbr0"
  description = "Local network bridge (NAT)"
  type        = "bridge"

  config = {
    "ipv4.address"     = "${local.vm_subnet.gateway}/${split("/", local.vm_subnet.cidr)[1]}"
    "ipv4.dhcp"        = "true"
    "ipv4.dhcp.ranges" = local.vm_subnet.dhcp_range
    "ipv4.nat"         = "true"
  }

  lifecycle {
    prevent_destroy = true
  }
}
