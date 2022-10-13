locals {
  hosts = {
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
    }
    rica = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = data.sops_file.rica.data["network.address"]
          ddns    = false
        }
      }
      ddns_records = {}
    }
    a1 = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = oci_core_instance.a1.public_ip
        }
      }
      ddns_records = {}
    }
    tencent = {
      records = {
        a = {
          proxied = false
          type    = "A"
          value   = data.sops_file.terraform.data["ip.tencent"]
        }
      }
      ddns_records = {}
    }
    vultr = {
      records = {
        a = {
          proxied = true
          type    = "A"
          value   = vultr_instance.main.main_ip
        }
        aaaa = {
          proxied = true
          type    = "AAAA"
          value   = vultr_instance.main.v6_main_ip
        }
      }
      ddns_records = {}
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
    }
    t460p = {
      records = {}
      ddns_records = {
        aaaa = {
          proxied = false
          type    = "AAAA"
          value   = "::1"
        }
      }
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
    }
    g150ts = {
      records      = {}
      ddns_records = {}
    }
  }
}

locals {
  host_numbers = [for n in random_integer.host_number : n.result]
}

resource "null_resource" "host_numbers_are_unique" {
  lifecycle {
    precondition {
      condition     = length(local.host_numbers) == length(distinct(local.host_numbers))
      error_message = "Host numbers should be unique."
    }
  }
}

resource "random_integer" "host_number" {
  for_each = local.hosts
  min      = local.zerotier_main_subnet_min_host_number
  max      = local.zerotier_main_subnet_max_host_number
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
  zerotier_ip         = cidrhost(local.zerotier_main_subnet_cidr, random_integer.host_number[each.key].result)
}

output "hosts" {
  value     = module.hosts
  sensitive = true
}
