locals {
  hosts = {
    hil0 = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = hcloud_server.hil0.ipv4_address
        }
        aaaa = {
          proxied = true
          type    = "AAAA"
          value   = hcloud_server.hil0.ipv6_address
        }
      }
      ddns_records      = {}
      dn42_host_indices = [1]
      endpoints_v4      = [hcloud_server.hil0.ipv4_address]
      endpoints_v6      = [hcloud_server.hil0.ipv6_address]
    }
    fsn0 = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = hcloud_server.fsn0.ipv4_address
        }
        aaaa = {
          proxied = true
          type    = "AAAA"
          value   = hcloud_server.fsn0.ipv6_address
        }
      }
      ddns_records      = {}
      dn42_host_indices = [2]
      endpoints_v4      = [hcloud_server.fsn0.ipv4_address]
      endpoints_v6      = [hcloud_server.fsn0.ipv6_address]
    }
    mtl0 = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = nonsensitive(data.sops_file.mtl0.data["network.address"])
        }
      }
      ddns_records      = {}
      dn42_host_indices = [3]
      endpoints_v4      = [nonsensitive(data.sops_file.mtl0.data["network.address"])]
      endpoints_v6      = []
    }
    mia0 = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = vultr_instance.mia0.main_ip
        }
        aaaa = {
          proxied = true
          type    = "AAAA"
          value   = vultr_instance.mia0.v6_main_ip
        }
      }
      ddns_records      = {}
      dn42_host_indices = [4]
      endpoints_v4      = [vultr_instance.mia0.main_ip]
      endpoints_v6      = [vultr_instance.mia0.v6_main_ip]
    }
    shg0 = {
      records = {
        a = {
          proxied = false
          type    = "A"
          value   = nonsensitive(data.sops_file.terraform.data["ip.shg0"])
        }
      }
      ddns_records      = {}
      dn42_host_indices = [5]
      endpoints_v4      = [nonsensitive(data.sops_file.terraform.data["ip.shg0"])]
      endpoints_v6      = []
    }
    nuc = {
      records = {}
      ddns_records = {
        a = {
          proxied = false
          type    = "A"
          value   = "127.0.0.1"
        }
        aaaa = {
          proxied = false
          type    = "AAAA"
          value   = "::1"
        }
      }
      dn42_host_indices = [6]
      endpoints_v4      = []
      endpoints_v6      = []
    }
    framework = {
      records = {}
      ddns_records = {
        aaaa = {
          proxied = false
          type    = "AAAA"
          value   = "::1"
        }
      }
      dn42_host_indices = [21]
      endpoints_v4      = []
      endpoints_v6      = []
    }
    xps8930 = {
      records = {}
      ddns_records = {
        a = {
          proxied = false
          type    = "A"
          value   = "127.0.0.1"
        }
        aaaa = {
          proxied = false
          type    = "AAAA"
          value   = "::1"
        }
      }
      dn42_host_indices = [22]
      endpoints_v4      = []
      endpoints_v6      = []
    }
  }
}

module "hosts" {
  source = "./modules/host"

  for_each = {
    for index, host_name in keys(local.hosts) :
    host_name => merge(
      { index = index },
      local.hosts[host_name]
    )
  }

  name                = each.key
  cloudflare_zone_id  = cloudflare_zone.com_li7g.id
  records             = each.value.records
  ddns_records        = each.value.ddns_records
  zerotier_network_id = zerotier_network.main.id
  dn42_host_indices   = each.value.dn42_host_indices
  dn42_v4_cidr        = var.dn42_v4_cidr
  dn42_v6_cidr        = var.dn42_v6_cidr
  endpoints_v4        = each.value.endpoints_v4
  endpoints_v6        = each.value.endpoints_v6
  ca_cert_pem         = tls_self_signed_cert.ca.cert_pem
  ca_private_key_pem  = tls_self_signed_cert.ca.private_key_pem
}

output "hosts" {
  value     = module.hosts
  sensitive = true
}
