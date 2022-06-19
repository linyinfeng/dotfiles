provider "zerotier" {
  zerotier_central_token = data.sops_file.terraform.data["zerotier.central-token"]
}

locals {
  zerotier_main_subnet                 = "172.29.0.0"
  zerotier_main_subnet_cidr            = "${local.zerotier_main_subnet}/${local.zerotier_main_subnet_bits}"
  zerotier_main_subnet_bits            = 16
  zerotier_main_subnet_min_host_number = 1
  zerotier_main_subnet_max_host_number = pow(2, local.zerotier_main_subnet_bits) - 2
}

resource "zerotier_network" "main" {
  name = "main"

  assign_ipv4 {
    zerotier = false
  }
  assign_ipv6 {
    zerotier = false
    sixplane = false
    rfc4193  = false
  }
  route {
    target = local.zerotier_main_subnet_cidr
  }

  enable_broadcast = true
  private          = true
  flow_rules       = <<EOF
# # allow only IPv4, IPv4 ARP, and IPv6 Ethernet frames.
# drop
#   not ethertype ipv4
#   and not ethertype arp
#   and not ethertype ipv6
# ;
# accept anything else
accept;
EOF
}

output "zerotier_network_id" {
  value     = zerotier_network.main.id
  sensitive = true
}
