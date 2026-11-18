locals {
  # 243 is the first byte of SHA-256("yinfeng"), in decimal.
  personal_ipv4_cidr = "10.243.0.0/16"

  # 183 is the first byte of SHA-256("ostrich"), in decimal.
  ostrich_incus_ipv4_cidr = cidrsubnet(local.personal_ipv4_cidr, 8, 183)

  # 181 is the first byte of SHA-256("wireguard-home"), in decimal.
  wireguard_home_ipv4_cidr = cidrsubnet(local.personal_ipv4_cidr, 8, 181)
}

output "subnets" {
  value = {
    personal = {
      cidr = local.personal_ipv4_cidr
    }

    ostrich-incus = {
      cidr    = local.ostrich_incus_ipv4_cidr
      gateway = cidrhost(local.ostrich_incus_ipv4_cidr, 1)
      nixos   = cidrhost(local.ostrich_incus_ipv4_cidr, 10)
      windows = cidrhost(local.ostrich_incus_ipv4_cidr, 20)
      dhcp_range = join("-", [
        cidrhost(local.ostrich_incus_ipv4_cidr, 100),
        cidrhost(local.ostrich_incus_ipv4_cidr, 199),
      ])
    }

    wireguard-home = {
      cidr        = local.wireguard_home_ipv4_cidr
      home-router = cidrhost(local.wireguard_home_ipv4_cidr, 1)
      parrot      = cidrhost(local.wireguard_home_ipv4_cidr, 2)
    }
  }
}
