provider "zerotier" {
  zerotier_central_token = data.sops_file.terraform.data["zerotier.central-token"]
}

data "zerotier_members" "all" {
  network_id = local.zerotier_network_id
}

locals {
  zerotier_hosts = {
    for member in data.zerotier_members.all.members :
    member.name => one(member.ipv4_assignments)
    if member.name != "" && length(member.ipv4_assignments) > 0
  }
}

resource "cloudflare_dns_record" "li7g_zt" {
  for_each = local.zerotier_hosts

  name    = "${each.key}.zt.${local.cloudflare_zone_name}"
  proxied = false
  ttl     = 1
  type    = "A"
  content = each.value
  zone_id = local.cloudflare_zone_id
}
