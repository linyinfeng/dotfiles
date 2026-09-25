provider "tailscale" {
  api_key = data.sops_file.terraform.data["tailscale.api-key"]
  tailnet = data.sops_file.terraform.data["tailscale.tailnet"]
}

locals {
  # the suffix is actually non-sensitive
  tailscale_account_suffix = nonsensitive(data.sops_file.terraform.data["tailscale.suffix"])

  # tailnet devices that are not NixOS hosts but still get a <name>.ts.li7g.com
  # record; NixOS hosts come from local.hosts
  extra_tailscale_devices = [
    "ostrich",
  ]
}

# stage interface for post-nixos: which names get a <name>.ts.li7g.com record
output "tailscale_hosts_json" {
  value = jsonencode(sort(concat(keys(local.hosts), local.extra_tailscale_devices)))
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

output "tailscale_tailnet_domain" {
  value = local.tailscale_account_suffix
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
