locals {
  hosts = {
    mtl0 = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = nonsensitive(data.sops_file.predefined.data["mtl0_network_address"])
        }
      }
      host_indices = [3]
      endpoints_v4 = [nonsensitive(data.sops_file.predefined.data["mtl0_network_address"])]
    }
    hkg0 = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = nonsensitive(data.sops_file.predefined.data["hkg0_network_address_v4"])
        }
        aaaa = {
          proxied = true
          type    = "AAAA"
          value   = nonsensitive(data.sops_file.predefined.data["hkg0_network_address_v6"])
        }
      }
      host_indices = [4]
      endpoints_v4 = [nonsensitive(data.sops_file.predefined.data["hkg0_network_address_v4"])]
      endpoints_v6 = [nonsensitive(data.sops_file.predefined.data["hkg0_network_address_v6"])]
    }
    nuc = {
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
      host_indices = [7]
      # the queue runner's gRPC endpoint is exposed under this name
      mtls_extra_dns_names = ["hydra-runner.li7g.com"]
    }
    ostrich = {
      host_indices = [8]
    }
    parrot = {
      ddns_records = {
        aaaa = {
          proxied = false
          type    = "AAAA"
          value   = "::1"
        }
      }
      host_indices = [21]
    }
    xps8930 = {
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
    }
    sparrow = {}
    # PLACEHOLDER new host
  }
}

locals {
  all_host_indices = flatten([for name, cfg in local.hosts : lookup(cfg, "host_indices", [])])
}

data "assert_test" "host_indices_collision" {
  test  = length(local.all_host_indices) == length(toset(local.all_host_indices))
  throw = "host indices collision"
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

  name                 = each.key
  cloudflare_zone_id   = cloudflare_zone.com_li7g.id
  cloudflare_zone_name = cloudflare_zone.com_li7g.name
  records              = lookup(each.value, "records", {})
  ddns_records         = lookup(each.value, "ddns_records", {})
  zerotier_network_id  = zerotier_network.main.id
  host_indices         = lookup(each.value, "host_indices", [])
  dn42_v4_cidr         = var.dn42_v4_cidr
  dn42_v6_cidr         = var.dn42_v6_cidr
  endpoints_v4         = lookup(each.value, "endpoints_v4", [])
  endpoints_v6         = lookup(each.value, "endpoints_v6", [])
  ca_cert_pem          = tls_self_signed_cert.ca.cert_pem
  ca_private_key_pem   = tls_self_signed_cert.ca.private_key_pem
  mtls_extra_dns_names = lookup(each.value, "mtls_extra_dns_names", [])
}

output "hosts" {
  value     = module.hosts
  sensitive = true
}

output "hosts_non_sensitive" {
  value = {
    for host, outputs in module.hosts :
    host => {
      for name, output in outputs :
      name => output if !issensitive(output)
    }
  }
  sensitive = false
}
