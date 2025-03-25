provider "tailscale" {
  api_key = data.sops_file.terraform.data["tailscale.api-key"]
  tailnet = data.sops_file.terraform.data["tailscale.tailnet"]
}

locals {
  # the suffix is actually non-sensitive
  tailscale_account_suffix = nonsensitive(data.sops_file.terraform.data["tailscale.suffix"])
}

resource "tailscale_tailnet_key" "tailnet_key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true

  lifecycle {
    replace_triggered_by = [
      time_static.rotate_monthly
    ]
  }
}

output "tailscale_tailnet_key" {
  value     = tailscale_tailnet_key.tailnet_key.key
  sensitive = true
}

resource "tailscale_acl" "main" {
  acl = jsonencode({
    acls : [
      {
        // allow all users access to all ports.
        action = "accept",
        ports  = ["*:*"],
        users  = ["*"],
      }
    ]
  })
}

data "tailscale_devices" "all" {
}

resource "cloudflare_dns_record" "li7g_ts" {
  for_each = {
    for device in data.tailscale_devices.all.devices :
    device.name =>
    [for address in device.addresses : address
      if can(cidrnetmask("${address}/32")) # ipv4 address only
    ][0]                                   # first ipv4 address
  }

  name    = "${trimsuffix(each.key, ".${local.tailscale_account_suffix}")}.ts.${cloudflare_zone.com_li7g.name}"
  proxied = false
  ttl     = 1
  type    = "A" # ipv4
  content = each.value
  zone_id = cloudflare_zone.com_li7g.id
}
