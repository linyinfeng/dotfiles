provider "zerotier" {
  zerotier_central_token = data.sops_file.terraform.data["zerotier.central-token"]
}

resource "zerotier_network" "main" {
  name = "main"

  assign_ipv4 {
    zerotier = true
  }

  assign_ipv6 {
    zerotier = false
    sixplane = false
    rfc4193  = false
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
