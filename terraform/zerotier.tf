provider "zerotier" {
  zerotier_central_token = data.sops_file.terraform.data["zerotier.central-token"]
}

locals {
  zerotier_main_subnet = "172.29.0.0/16"
}

resource "zerotier_network" "main" {
  name = "main"

  # no auto ip address assignment
  assign_ipv4 {
    zerotier = false
  }
  assign_ipv6 {
    zerotier = false
    sixplane = false
    rfc4193  = false
  }

  route {
    target = local.zerotier_main_subnet
  }

  enable_broadcast = true
  private          = true
  flow_rules       = <<EOF
# allow only IPv4, IPv4 ARP, and IPv6 Ethernet frames.
drop
  not ethertype ipv4
  and not ethertype arp
  and not ethertype ipv6
;
# accept anything else
accept;
EOF
}

output "zerotier_network_id" {
  value     = zerotier_network.main.id
  sensitive = true
}
