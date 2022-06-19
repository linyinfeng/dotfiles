locals {
    hosts = {
        aws = {
            records = {
                a = {
                    proxied = true
                    type    = "A"
                    value   = aws_eip.main.public_ip
                    ddns = false
                }
                aaaa = {
                    proxied = true
                    type    = "AAAA"
                    value   = aws_instance.main.ipv6_addresses[0]
                    ddns = false
                }
            }
            ddns_records = { }
        }
        nuc = {
            records = { }
            ddns_records = {
                a = {
                    proxied = false
                    type    = "A"
                    value   = "127.0.0.1"
                }
                aaaa = {
                    proxied = false
                    type = "AAAA"
                    value = "::1"
                }
            }
        }
        rica = {
            records = {
                a = {
                    proxied = true
                    type    = "A"
                    value = data.sops_file.rica.data["network.address"]
                    ddns = false
                }
            }
            ddns_records = { }
        }
        tencent = {
            records = {
                a = {
                    proxied = false
                    type    = "A"
                    value = data.sops_file.terraform.data["ip.tencent"]
                    ddns = false
                }
            }
            ddns_records = { }
        }
        vultr = {
            records = {
                a = {
                    proxied = true
                    type    = "A"
                    value = vultr_instance.main.main_ip
                    ddns = false
                }
                aaaa = {
                    proxied = true
                    type    = "AAAA"
                    value = vultr_instance.main.v6_main_ip
                    ddns = false
                }
            }
            ddns_records = { }
        }
        t460p = {
            records = { }
            ddns_records = {
                a = {
                    proxied = false
                    type    = "A"
                    value   = "127.0.0.1"
                }
                aaaa = {
                    proxied = false
                    type = "AAAA"
                    value = "::1"
                }
            }
        }
        xps8930 = {
            records = { }
            ddns_records = {
                a = {
                    proxied = false
                    type    = "A"
                    value   = "127.0.0.1"
                }
                aaaa = {
                    proxied = false
                    type = "AAAA"
                    value = "::1"
                }
            }
        }
    }
}

module "hosts" {
  source   = "./modules/host"

  for_each = local.hosts

  name         = each.key
  #server       = each.value.server
  cloudflare_zone_id = cloudflare_zone.com_li7g.id
  records      = each.value.records
  ddns_records = each.value.ddns_records
  zerotier_network_id = zerotier_network.main.id
}

output "hosts" {
  value = module.hosts
}
