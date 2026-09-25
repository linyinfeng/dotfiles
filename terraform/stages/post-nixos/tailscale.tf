provider "cloudflare" {
  api_token = data.sops_file.terraform.data["cloudflare.api-token"]
}

provider "tailscale" {
  api_key = data.sops_file.terraform.data["tailscale.api-key"]
  tailnet = data.sops_file.terraform.data["tailscale.tailnet"]
}

locals {
  # the suffix is actually non-sensitive
  tailscale_account_suffix = nonsensitive(data.sops_file.terraform.data["tailscale.suffix"])

  tailscale_devices = {
    for device in data.tailscale_devices.all.devices :
    trimsuffix(device.name, ".${local.tailscale_account_suffix}") => device
  }

  # Only the names pre-nixos knows about get a record, so devices joining or
  # leaving the tailnet cannot add or remove records behind our back. A known
  # name whose device is not in the tailnet right now gets no record; the
  # check below reports it instead of failing the plan.
  ts_record_addresses = {
    for name in local.tailscale_hosts : name =>
    [for address in local.tailscale_devices[name].addresses : address
      if can(cidrnetmask("${address}/32")) # ipv4 address only
    ][0]                                   # first ipv4 address
    if contains(keys(local.tailscale_devices), name)
  }
}

check "tailscale_hosts_present" {
  assert {
    condition = alltrue([
      for name in local.tailscale_hosts : contains(keys(local.tailscale_devices), name)
    ])
    error_message = "known names without a tailnet device (no record created): ${join(", ", [
      for name in local.tailscale_hosts : name
      if !contains(keys(local.tailscale_devices), name)
    ])}"
  }
}

data "tailscale_devices" "all" {
}

# Records can only exist once the device has joined the tailnet, i.e. after the
# NixOS deployment; the names themselves come from pre-nixos. Service names
# (<service>.ts.li7g.com) stay in pre-nixos, so the wildcard certificate covers
# all of them and no per-device certificate is needed.
resource "cloudflare_dns_record" "li7g_ts" {
  for_each = local.ts_record_addresses

  name    = "${each.key}.ts.${local.cloudflare_zone_name}"
  proxied = false
  ttl     = 1
  type    = "A" # ipv4
  content = each.value
  zone_id = local.cloudflare_zone_id
}
